//
//  MomentumBarTests.swift
//  MomentumBarTests
//
//  Created by Youssef Abdellaoui on 01.01.26.
//

import Testing
import Foundation
import SwiftUI
@testable import MomentumBar

// MARK: - Meeting Link Parser Tests
struct MeetingLinkParserTests {

    @Test func detectsZoomLink() throws {
        let text = "Join us at https://zoom.us/j/1234567890 for the meeting"
        let link = MeetingLinkParser.extractMeetingLink(from: text)

        #expect(link != nil)
        #expect(link?.platform == .zoom)
        #expect(link?.url.absoluteString.contains("zoom.us") == true)
    }

    @Test func detectsGoogleMeetLink() throws {
        let text = "Meeting link: https://meet.google.com/abc-defg-hij"
        let link = MeetingLinkParser.extractMeetingLink(from: text)

        #expect(link != nil)
        #expect(link?.platform == .googleMeet)
        #expect(link?.url.absoluteString.contains("meet.google.com") == true)
    }

    @Test func detectsTeamsLink() throws {
        let text = "Join Teams: https://teams.microsoft.com/l/meetup-join/abc123"
        let link = MeetingLinkParser.extractMeetingLink(from: text)

        #expect(link != nil)
        #expect(link?.platform == .teams)
    }

    @Test func detectsWebexLink() throws {
        let text = "Webex meeting: https://company.webex.com/meet/username"
        let link = MeetingLinkParser.extractMeetingLink(from: text)

        #expect(link != nil)
        #expect(link?.platform == .webex)
    }

    @Test func returnsNilForNoLink() throws {
        let text = "No meeting link in this text"
        let link = MeetingLinkParser.extractMeetingLink(from: text)

        #expect(link == nil)
    }

    @Test func returnsNilForEmptyString() throws {
        let link = MeetingLinkParser.extractMeetingLink(from: "")
        #expect(link == nil)
    }

    @Test func parsesDirectZoomURL() throws {
        let url = URL(string: "https://zoom.us/j/9876543210")!
        let link = MeetingLinkParser.parseMeetingURL(url)

        #expect(link != nil)
        #expect(link?.platform == .zoom)
    }
}

// MARK: - Time Zone Entry Tests
struct TimeZoneEntryTests {

    @Test func createsValidEntry() throws {
        let entry = TimeZoneEntry(
            identifier: "America/New_York",
            customName: "NYC Office",
            order: 0
        )

        #expect(entry.identifier == "America/New_York")
        #expect(entry.customName == "NYC Office")
        #expect(entry.displayName == "NYC Office")
        #expect(entry.timeZone != nil)
    }

    @Test func displaysDefaultNameWhenNoCustomName() throws {
        let entry = TimeZoneEntry(
            identifier: "America/Los_Angeles",
            order: 0
        )

        #expect(entry.customName == nil)
        #expect(entry.displayName.isEmpty == false)
    }

    @Test func extractsCityName() throws {
        let entry = TimeZoneEntry(identifier: "Europe/London", order: 0)
        #expect(entry.cityName == "London")

        let entry2 = TimeZoneEntry(identifier: "America/New_York", order: 0)
        #expect(entry2.cityName == "New York")
    }

    @Test func calculatesOffset() throws {
        let entry = TimeZoneEntry(identifier: "UTC", order: 0)
        #expect(entry.currentOffset.contains("UTC"))
    }

    @Test func abbreviationIsNotEmpty() throws {
        let entry = TimeZoneEntry(identifier: "Asia/Tokyo", order: 0)
        #expect(entry.abbreviation.isEmpty == false)
    }
}

// MARK: - Time Zone Service Tests
struct TimeZoneServiceTests {

    @Test func searchFindsNewYork() throws {
        let service = TimeZoneService.shared
        let results = service.searchTimeZones(query: "New York")

        #expect(results.isEmpty == false)
        #expect(results.contains { $0.identifier == "America/New_York" })
    }

    @Test func searchFindsTokyo() throws {
        let service = TimeZoneService.shared
        let results = service.searchTimeZones(query: "Tokyo")

        #expect(results.isEmpty == false)
        #expect(results.contains { $0.identifier == "Asia/Tokyo" })
    }

    @Test func searchIsCaseInsensitive() throws {
        let service = TimeZoneService.shared

        let results1 = service.searchTimeZones(query: "LONDON")
        let results2 = service.searchTimeZones(query: "london")
        let results3 = service.searchTimeZones(query: "London")

        #expect(results1.count == results2.count)
        #expect(results2.count == results3.count)
    }

    @Test func searchReturnsEmptyForNoMatch() throws {
        let service = TimeZoneService.shared
        let results = service.searchTimeZones(query: "xyznotacityxyz")

        #expect(results.isEmpty)
    }

    @Test func searchReturnsEmptyForEmptyQuery() throws {
        let service = TimeZoneService.shared
        let results = service.searchTimeZones(query: "")

        #expect(results.isEmpty)
    }

    @Test func popularTimeZonesNotEmpty() throws {
        let service = TimeZoneService.shared
        let popular = service.popularTimeZones()

        #expect(popular.isEmpty == false)
        #expect(popular.count >= 5)
    }

    @Test func getTimeZoneInfoReturnsValidInfo() throws {
        let service = TimeZoneService.shared
        let info = service.getTimeZoneInfo(for: "America/New_York")

        #expect(info != nil)
        #expect(info?.identifier == "America/New_York")
        #expect(info?.cityName == "New York")
    }
}

// MARK: - App Preferences Tests
struct AppPreferencesTests {

    @Test func defaultPreferencesAreValid() throws {
        let prefs = AppPreferences.default

        #expect(prefs.use24HourFormat == false)
        #expect(prefs.showSeconds == false)
        #expect(prefs.showDayNightIndicator == true)
        #expect(prefs.meetingReminderMinutes == 10)
    }

    @Test func preferencesAreCodable() throws {
        let prefs = AppPreferences(
            use24HourFormat: true,
            showSeconds: true,
            showDayNightIndicator: false,
            menuBarDisplayMode: .time,
            meetingReminderMinutes: 5
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(prefs)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppPreferences.self, from: data)

        #expect(decoded.use24HourFormat == true)
        #expect(decoded.showSeconds == true)
        #expect(decoded.showDayNightIndicator == false)
        #expect(decoded.menuBarDisplayMode == .time)
        #expect(decoded.meetingReminderMinutes == 5)
    }
}

// MARK: - Color Extension Tests
struct ColorExtensionTests {

    @Test func parsesValidHexColor() throws {
        let color = Color(hex: "#FF0000")
        #expect(color != nil)
    }

    @Test func parsesHexWithoutHash() throws {
        let color = Color(hex: "00FF00")
        #expect(color != nil)
    }

    @Test func returnsNilForInvalidHex() throws {
        let color = Color(hex: "notahex")
        #expect(color == nil)
    }
}
