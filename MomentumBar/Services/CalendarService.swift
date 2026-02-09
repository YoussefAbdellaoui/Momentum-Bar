//
//  CalendarService.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation
import EventKit
import Combine
import AppKit

@MainActor
final class CalendarService: ObservableObject {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()
    private var authCheckTimer: Timer?

    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var availableCalendars: [EKCalendar] = []
    @Published var upcomingEvents: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var overlaps: [MeetingOverlap] = []
    @Published var bufferWarnings: [String: BufferWarning] = [:]
    @Published var lastSyncAt: Date?
    @Published var lastErrorMessage: String?

    private var canReadEvents: Bool {
        if authorizationStatus == .fullAccess {
            return true
        }
        if #available(macOS 14.0, *) {
            return false
        }
        return authorizationStatus == .authorized
    }

    private var canWriteEvents: Bool {
        if authorizationStatus == .fullAccess || authorizationStatus == .writeOnly {
            return true
        }
        if #available(macOS 14.0, *) {
            return false
        }
        return authorizationStatus == .authorized
    }

    var hasOverlaps: Bool {
        !overlaps.isEmpty
    }

    var hasBufferWarnings: Bool {
        !bufferWarnings.isEmpty
    }

    var bufferWarningCount: Int {
        bufferWarnings.count
    }

    var overlappingEventIDs: Set<String> {
        Set(overlaps.flatMap { $0.events.map { $0.id } })
    }

    func isOverlapping(_ event: CalendarEvent) -> Bool {
        overlappingEventIDs.contains(event.id)
    }

    func getOverlappingEvents(for event: CalendarEvent) -> [CalendarEvent] {
        OverlapDetector.overlappingEvents(for: event, in: upcomingEvents)
    }

    func hasBufferWarning(_ event: CalendarEvent) -> Bool {
        bufferWarnings[event.id] != nil
    }

    func getBufferWarning(for event: CalendarEvent) -> BufferWarning? {
        bufferWarnings[event.id]
    }

    private init() {
        updateAuthorizationStatus()
        setupNotifications()
        startAuthorizationMonitoring()
        if canReadEvents {
            loadCalendars()
            fetchUpcomingEvents()
        }
    }

    deinit {
        authCheckTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup
    private func setupNotifications() {
        // Listen for calendar store changes (events added/modified/deleted)
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.handleCalendarStoreChanged()
            }
        }
    }

    private func startAuthorizationMonitoring() {
        // Periodically check authorization status when not yet granted
        // This catches when user grants permission in System Settings
        authCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.checkAuthorizationChange()
            }
        }
    }

    private func checkAuthorizationChange() {
        let currentStatus = EKEventStore.authorizationStatus(for: .event)
        if currentStatus != authorizationStatus {
            let wasNotAuthorized = !canReadEvents
            authorizationStatus = currentStatus

            // If we just got authorized, load calendars and events
            if wasNotAuthorized && (currentStatus == .fullAccess || (!isMacOS14OrNewer && currentStatus == .authorized)) {
                loadCalendars()
                fetchUpcomingEvents()
            }
        }

        // Stop polling once we have full access
        if currentStatus == .fullAccess || (!isMacOS14OrNewer && currentStatus == .authorized) {
            authCheckTimer?.invalidate()
            authCheckTimer = nil
        }
    }

    private var isMacOS14OrNewer: Bool {
        if #available(macOS 14.0, *) {
            return true
        }
        return false
    }

    private func handleCalendarStoreChanged() {
        // Refresh data when calendar store changes
        if canReadEvents {
            loadCalendars()
            fetchUpcomingEvents()
        }
    }

    // MARK: - Authorization
    func updateAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if canReadEvents {
            loadCalendars()
            fetchUpcomingEvents()
        } else {
            lastErrorMessage = "Calendar access not granted."
        }
    }

    func requestAccessOrOpenSettings() async {
        updateAuthorizationStatus()
        switch authorizationStatus {
        case .notDetermined:
            _ = await requestAccess()
        case .restricted, .denied:
            openCalendarSystemSettings()
        default:
            break
        }
    }

    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                updateAuthorizationStatus()
                if granted {
                    loadCalendars()
                }
            }
            return granted
        } catch {
            print("Calendar access request failed: \(error)")
            lastErrorMessage = "Calendar access request failed."
            return false
        }
    }

    func openCalendarSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Calendars
    func loadCalendars() {
        guard canReadEvents else { return }
        availableCalendars = eventStore.calendars(for: .event)
    }

    // MARK: - Events
    func fetchUpcomingEvents(hours: Int = 168, calendarIDs: Set<String>? = nil) {
        guard canReadEvents else { return }

        isLoading = true
        lastErrorMessage = nil

        let calendars: [EKCalendar]?
        if let ids = calendarIDs, !ids.isEmpty {
            calendars = availableCalendars.filter { ids.contains($0.calendarIdentifier) }
        } else {
            calendars = nil // All calendars
        }

        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .hour, value: hours, to: startDate) ?? startDate

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )

        let ekEvents = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }

        upcomingEvents = ekEvents.map { CalendarEvent(from: $0) }
        overlaps = OverlapDetector.findOverlaps(in: upcomingEvents)

        // Compute buffer warnings based on user preferences
        let preferences = StorageService.shared.loadPreferences()
        if preferences.showBufferWarnings {
            bufferWarnings = BufferDetector.findBufferWarnings(
                in: upcomingEvents,
                minimumBufferMinutes: preferences.minimumBufferMinutes
            )
        } else {
            bufferWarnings = [:]
        }

        isLoading = false
        lastSyncAt = Date()
    }

    func fetchRecentEvents(hours: Int = 2) -> [CalendarEvent] {
        guard canReadEvents else { return [] }

        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -hours, to: endDate) ?? endDate

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )

        let ekEvents = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }

        let events = ekEvents.map { CalendarEvent(from: $0) }

        // Record completed meetings for analytics
        MeetingAnalyticsService.shared.recordMeetings(from: events.filter { $0.isPast })

        return events
    }

    /// Record analytics for completed events
    func recordCompletedMeetings() {
        let recentEvents = fetchRecentEvents(hours: 24)
        MeetingAnalyticsService.shared.recordMeetings(from: recentEvents.filter { $0.isPast })
    }

    // MARK: - Refresh
    func refresh() {
        guard canReadEvents else { return }
        loadCalendars()
        fetchUpcomingEvents()
    }

    // MARK: - Event Management (CRUD)

    /// Get the underlying EKEvent for a CalendarEvent
    func getEKEvent(for event: CalendarEvent) -> EKEvent? {
        eventStore.event(withIdentifier: event.id)
    }

    /// Create a new calendar event
    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool = false,
        calendar: EKCalendar? = nil,
        notes: String? = nil,
        location: String? = nil,
        url: URL? = nil
    ) throws -> CalendarEvent {
        guard canWriteEvents else {
            throw CalendarError.notAuthorized
        }

        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.isAllDay = isAllDay
        event.calendar = calendar ?? eventStore.defaultCalendarForNewEvents
        event.notes = notes
        event.location = location
        event.url = url

        try eventStore.save(event, span: .thisEvent)
        refresh()

        return CalendarEvent(from: event)
    }

    /// Update an existing calendar event
    func updateEvent(
        _ event: CalendarEvent,
        title: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        isAllDay: Bool? = nil,
        notes: String? = nil,
        location: String? = nil,
        url: URL? = nil
    ) throws {
        guard canWriteEvents else {
            throw CalendarError.notAuthorized
        }

        guard let ekEvent = eventStore.event(withIdentifier: event.id) else {
            throw CalendarError.eventNotFound
        }

        if let title = title { ekEvent.title = title }
        if let startDate = startDate { ekEvent.startDate = startDate }
        if let endDate = endDate { ekEvent.endDate = endDate }
        if let isAllDay = isAllDay { ekEvent.isAllDay = isAllDay }
        if let notes = notes { ekEvent.notes = notes }
        if let location = location { ekEvent.location = location }
        if let url = url { ekEvent.url = url }

        try eventStore.save(ekEvent, span: .thisEvent)
        refresh()
    }

    /// Delete a calendar event
    func deleteEvent(_ event: CalendarEvent) throws {
        guard canWriteEvents else {
            throw CalendarError.notAuthorized
        }

        guard let ekEvent = eventStore.event(withIdentifier: event.id) else {
            throw CalendarError.eventNotFound
        }

        try eventStore.remove(ekEvent, span: .thisEvent)
        refresh()
    }

    /// Get default calendar for new events
    var defaultCalendar: EKCalendar? {
        eventStore.defaultCalendarForNewEvents
    }

    /// Get writable calendars only
    var writableCalendars: [EKCalendar] {
        availableCalendars.filter { $0.allowsContentModifications }
    }

    // MARK: - ICS Import/Export

    /// Export events to ICS format
    func exportToICS(events: [CalendarEvent]) -> String {
        var icsContent = "BEGIN:VCALENDAR\r\n"
        icsContent += "VERSION:2.0\r\n"
        icsContent += "PRODID:-//MomentumBar//EN\r\n"
        icsContent += "CALSCALE:GREGORIAN\r\n"
        icsContent += "METHOD:PUBLISH\r\n"

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")

        let dateDateFormatter = DateFormatter()
        dateDateFormatter.dateFormat = "yyyyMMdd"
        dateDateFormatter.timeZone = TimeZone(identifier: "UTC")

        for event in events {
            icsContent += "BEGIN:VEVENT\r\n"
            icsContent += "UID:\(event.id)@momentumbar\r\n"

            if event.isAllDay {
                icsContent += "DTSTART;VALUE=DATE:\(dateDateFormatter.string(from: event.startDate))\r\n"
                icsContent += "DTEND;VALUE=DATE:\(dateDateFormatter.string(from: event.endDate))\r\n"
            } else {
                icsContent += "DTSTART:\(dateFormatter.string(from: event.startDate))\r\n"
                icsContent += "DTEND:\(dateFormatter.string(from: event.endDate))\r\n"
            }

            icsContent += "SUMMARY:\(escapeICSText(event.title))\r\n"

            if let location = event.location, !location.isEmpty {
                icsContent += "LOCATION:\(escapeICSText(location))\r\n"
            }

            if let notes = event.notes, !notes.isEmpty {
                icsContent += "DESCRIPTION:\(escapeICSText(notes))\r\n"
            }

            if let url = event.url {
                icsContent += "URL:\(url.absoluteString)\r\n"
            }

            icsContent += "END:VEVENT\r\n"
        }

        icsContent += "END:VCALENDAR\r\n"
        return icsContent
    }

    /// Import events from ICS file
    func importFromICS(url: URL, to calendar: EKCalendar) throws -> Int {
        guard canWriteEvents else {
            throw CalendarError.notAuthorized
        }

        let icsContent = try String(contentsOf: url, encoding: .utf8)
        let events = parseICS(icsContent)

        var importedCount = 0
        for eventData in events {
            let event = EKEvent(eventStore: eventStore)
            event.title = eventData.title
            event.startDate = eventData.startDate
            event.endDate = eventData.endDate
            event.isAllDay = eventData.isAllDay
            event.calendar = calendar
            event.notes = eventData.notes
            event.location = eventData.location

            if let urlString = eventData.url, let url = URL(string: urlString) {
                event.url = url
            }

            try eventStore.save(event, span: .thisEvent)
            importedCount += 1
        }

        refresh()
        return importedCount
    }

    private func escapeICSText(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: "\n", with: "\\n")
    }

    private func parseICS(_ content: String) -> [ICSEventData] {
        var events: [ICSEventData] = []
        let lines = content.components(separatedBy: .newlines)

        var currentEvent: ICSEventData?
        var inEvent = false

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")

        let dateDateFormatter = DateFormatter()
        dateDateFormatter.dateFormat = "yyyyMMdd"
        dateDateFormatter.timeZone = TimeZone(identifier: "UTC")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed == "BEGIN:VEVENT" {
                inEvent = true
                currentEvent = ICSEventData()
            } else if trimmed == "END:VEVENT" {
                if let event = currentEvent, event.title != nil, event.startDate != nil {
                    events.append(event)
                }
                currentEvent = nil
                inEvent = false
            } else if inEvent, var event = currentEvent {
                if trimmed.hasPrefix("SUMMARY:") {
                    event.title = String(trimmed.dropFirst(8)).unescapeICS()
                } else if trimmed.hasPrefix("DTSTART:") {
                    let dateStr = String(trimmed.dropFirst(8))
                    event.startDate = dateFormatter.date(from: dateStr)
                    event.isAllDay = false
                } else if trimmed.hasPrefix("DTSTART;VALUE=DATE:") {
                    let dateStr = String(trimmed.dropFirst(19))
                    event.startDate = dateDateFormatter.date(from: dateStr)
                    event.isAllDay = true
                } else if trimmed.hasPrefix("DTEND:") {
                    let dateStr = String(trimmed.dropFirst(6))
                    event.endDate = dateFormatter.date(from: dateStr)
                } else if trimmed.hasPrefix("DTEND;VALUE=DATE:") {
                    let dateStr = String(trimmed.dropFirst(17))
                    event.endDate = dateDateFormatter.date(from: dateStr)
                } else if trimmed.hasPrefix("DESCRIPTION:") {
                    event.notes = String(trimmed.dropFirst(12)).unescapeICS()
                } else if trimmed.hasPrefix("LOCATION:") {
                    event.location = String(trimmed.dropFirst(9)).unescapeICS()
                } else if trimmed.hasPrefix("URL:") {
                    event.url = String(trimmed.dropFirst(4))
                }
                currentEvent = event
            }
        }

        return events
    }
}

// MARK: - Calendar Errors
enum CalendarError: LocalizedError {
    case notAuthorized
    case eventNotFound
    case saveFailed
    case importFailed

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Calendar access not authorized"
        case .eventNotFound:
            return "Event not found"
        case .saveFailed:
            return "Failed to save event"
        case .importFailed:
            return "Failed to import events"
        }
    }
}

// MARK: - ICS Event Data
private struct ICSEventData {
    var title: String?
    var startDate: Date?
    var endDate: Date?
    var isAllDay: Bool = false
    var notes: String?
    var location: String?
    var url: String?
}

// MARK: - String Extension for ICS
private extension String {
    func unescapeICS() -> String {
        self.replacingOccurrences(of: "\\n", with: "\n")
            .replacingOccurrences(of: "\\,", with: ",")
            .replacingOccurrences(of: "\\;", with: ";")
            .replacingOccurrences(of: "\\\\", with: "\\")
    }
}
