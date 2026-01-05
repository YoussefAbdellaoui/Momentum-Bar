//
//  CalendarEvent.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation
import EventKit

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarTitle: String
    let calendarColorHex: String
    let notes: String?
    let location: String?
    let url: URL?

    init(from ekEvent: EKEvent) {
        self.id = ekEvent.eventIdentifier ?? UUID().uuidString
        self.title = ekEvent.title ?? "Untitled Event"
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.isAllDay = ekEvent.isAllDay
        self.calendarTitle = ekEvent.calendar?.title ?? "Calendar"
        self.calendarColorHex = ekEvent.calendar?.cgColor?.toHex() ?? "#007AFF"
        self.notes = ekEvent.notes
        self.location = ekEvent.location
        self.url = ekEvent.url
    }

    var isOngoing: Bool {
        let now = Date()
        return now >= startDate && now <= endDate
    }

    var isUpcoming: Bool {
        Date() < startDate
    }

    var isPast: Bool {
        Date() > endDate
    }

    var progress: Double {
        guard isOngoing else { return 0 }
        let total = endDate.timeIntervalSince(startDate)
        let elapsed = Date().timeIntervalSince(startDate)
        return min(max(elapsed / total, 0), 1)
    }

    var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"

        if isAllDay {
            return "All day"
        }

        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }

    var minutesUntilStart: Int {
        let interval = startDate.timeIntervalSince(Date())
        return max(0, Int(interval / 60))
    }

    var meetingLink: MeetingLink? {
        // Check notes first
        if let notes = notes, let link = MeetingLinkParser.extractMeetingLink(from: notes) {
            return link
        }
        // Check location
        if let location = location, let link = MeetingLinkParser.extractMeetingLink(from: location) {
            return link
        }
        // Check URL
        if let url = url {
            return MeetingLinkParser.parseMeetingURL(url)
        }
        return nil
    }

    var durationMinutes: Int {
        Int(endDate.timeIntervalSince(startDate) / 60)
    }

    func overlaps(with other: CalendarEvent) -> Bool {
        guard id != other.id else { return false }
        guard !isAllDay && !other.isAllDay else { return false }
        return startDate < other.endDate && endDate > other.startDate
    }
}

// MARK: - Meeting Overlap
struct MeetingOverlap: Identifiable {
    let id = UUID()
    let events: [CalendarEvent]
    let overlapStart: Date
    let overlapEnd: Date

    var overlapDuration: TimeInterval {
        overlapEnd.timeIntervalSince(overlapStart)
    }

    var overlapMinutes: Int {
        Int(overlapDuration / 60)
    }
}

// MARK: - Overlap Detection
struct OverlapDetector {
    static func findOverlaps(in events: [CalendarEvent]) -> [MeetingOverlap] {
        var overlaps: [MeetingOverlap] = []
        let nonAllDayEvents = events.filter { !$0.isAllDay }

        for i in 0..<nonAllDayEvents.count {
            for j in (i + 1)..<nonAllDayEvents.count {
                let event1 = nonAllDayEvents[i]
                let event2 = nonAllDayEvents[j]

                if event1.overlaps(with: event2) {
                    let overlapStart = max(event1.startDate, event2.startDate)
                    let overlapEnd = min(event1.endDate, event2.endDate)

                    overlaps.append(MeetingOverlap(
                        events: [event1, event2],
                        overlapStart: overlapStart,
                        overlapEnd: overlapEnd
                    ))
                }
            }
        }

        return overlaps
    }

    static func hasOverlap(_ event: CalendarEvent, in events: [CalendarEvent]) -> Bool {
        events.contains { $0.overlaps(with: event) }
    }

    static func overlappingEvents(for event: CalendarEvent, in events: [CalendarEvent]) -> [CalendarEvent] {
        events.filter { $0.overlaps(with: event) }
    }
}

// MARK: - CGColor Extension
extension CGColor {
    func toHex() -> String {
        guard let components = self.components, components.count >= 3 else {
            return "#007AFF"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - Meeting Link
struct MeetingLink {
    let url: URL
    let platform: Platform

    enum Platform: String {
        case zoom = "Zoom"
        case googleMeet = "Google Meet"
        case teams = "Microsoft Teams"
        case webex = "Webex"
        case slack = "Slack Huddle"
        case unknown = "Meeting"

        var iconName: String {
            switch self {
            case .zoom: return "video.fill"
            case .googleMeet: return "video.fill"
            case .teams: return "person.3.fill"
            case .webex: return "video.fill"
            case .slack: return "bubble.left.and.bubble.right.fill"
            case .unknown: return "link"
            }
        }
    }
}

// MARK: - Meeting Link Parser
struct MeetingLinkParser {
    private static let zoomPattern = try! NSRegularExpression(
        pattern: #"https?://[\w.-]*zoom\.us/[jw]/\d+"#,
        options: .caseInsensitive
    )

    private static let meetPattern = try! NSRegularExpression(
        pattern: #"https?://meet\.google\.com/[a-z]{3}-[a-z]{4}-[a-z]{3}"#,
        options: .caseInsensitive
    )

    private static let teamsPattern = try! NSRegularExpression(
        pattern: #"https?://teams\.microsoft\.com/l/meetup-join/[\w%.-]+"#,
        options: .caseInsensitive
    )

    private static let webexPattern = try! NSRegularExpression(
        pattern: #"https?://[\w.-]*\.webex\.com/[\w/.-]+"#,
        options: .caseInsensitive
    )

    private static let slackPattern = try! NSRegularExpression(
        pattern: #"https?://(?:app\.)?slack\.com/huddle/[\w/-]+"#,
        options: .caseInsensitive
    )

    static func extractMeetingLink(from text: String) -> MeetingLink? {
        let range = NSRange(text.startIndex..., in: text)

        let patterns: [(NSRegularExpression, MeetingLink.Platform)] = [
            (zoomPattern, .zoom),
            (meetPattern, .googleMeet),
            (teamsPattern, .teams),
            (webexPattern, .webex),
            (slackPattern, .slack)
        ]

        for (regex, platform) in patterns {
            if let match = regex.firstMatch(in: text, options: [], range: range) {
                if let urlRange = Range(match.range, in: text),
                   let url = URL(string: String(text[urlRange])) {
                    return MeetingLink(url: url, platform: platform)
                }
            }
        }

        return nil
    }

    static func parseMeetingURL(_ url: URL) -> MeetingLink? {
        let urlString = url.absoluteString.lowercased()

        if urlString.contains("zoom.us") {
            return MeetingLink(url: url, platform: .zoom)
        } else if urlString.contains("meet.google.com") {
            return MeetingLink(url: url, platform: .googleMeet)
        } else if urlString.contains("teams.microsoft.com") {
            return MeetingLink(url: url, platform: .teams)
        } else if urlString.contains("webex.com") {
            return MeetingLink(url: url, platform: .webex)
        } else if urlString.contains("slack.com/huddle") {
            return MeetingLink(url: url, platform: .slack)
        }

        return nil
    }
}
