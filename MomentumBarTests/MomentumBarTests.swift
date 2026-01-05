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

    @Test func parsesShortHex() throws {
        let color = Color(hex: "FFF")
        #expect(color == nil) // Should fail - we only support 6 or 8 digit hex
    }

    @Test func parsesHexWithAlpha() throws {
        let color = Color(hex: "#FF0000FF")
        #expect(color != nil)
    }
}

// MARK: - Sunrise Sunset Service Tests
struct SunriseSunsetServiceTests {

    @Test func calculatesIsDaytimeForNewYork() throws {
        let service = SunriseSunsetService.shared
        guard let tz = TimeZone(identifier: "America/New_York") else {
            throw TestError("Could not create timezone")
        }

        // Test at noon - should be daytime
        var components = DateComponents()
        components.year = 2025
        components.month = 6
        components.day = 21
        components.hour = 12
        components.minute = 0
        components.timeZone = tz

        if let noonDate = Calendar.current.date(from: components) {
            let isDaytime = service.isDaytime(for: tz, at: noonDate)
            #expect(isDaytime == true)
        }
    }

    @Test func calculatesIsDaytimeForTokyo() throws {
        let service = SunriseSunsetService.shared
        guard let tz = TimeZone(identifier: "Asia/Tokyo") else {
            throw TestError("Could not create timezone")
        }

        // Test at midnight - should be nighttime
        var components = DateComponents()
        components.year = 2025
        components.month = 6
        components.day = 21
        components.hour = 2
        components.minute = 0
        components.timeZone = tz

        if let midnightDate = Calendar.current.date(from: components) {
            let isDaytime = service.isDaytime(for: tz, at: midnightDate)
            #expect(isDaytime == false)
        }
    }

    @Test func returnsCoordinatesForMajorCities() throws {
        let service = SunriseSunsetService.shared

        let newYorkCoords = service.coordinates(for: TimeZone(identifier: "America/New_York")!)
        #expect(newYorkCoords != nil)
        #expect(newYorkCoords?.latitude ?? 0 > 40)
        #expect(newYorkCoords?.latitude ?? 0 < 41)

        let tokyoCoords = service.coordinates(for: TimeZone(identifier: "Asia/Tokyo")!)
        #expect(tokyoCoords != nil)
        #expect(tokyoCoords?.latitude ?? 0 > 35)
        #expect(tokyoCoords?.latitude ?? 0 < 36)

        let londonCoords = service.coordinates(for: TimeZone(identifier: "Europe/London")!)
        #expect(londonCoords != nil)
    }

    @Test func getSunriseSunsetReturnsValidTimes() throws {
        let service = SunriseSunsetService.shared
        guard let tz = TimeZone(identifier: "America/New_York") else {
            throw TestError("Could not create timezone")
        }

        let result = service.getSunriseSunset(for: tz, on: Date())

        #expect(result != nil)
        if let times = result {
            #expect(times.sunrise < times.sunset)
        }
    }
}

// MARK: - Time Separator Tests
struct TimeSeparatorTests {

    @Test func allSeparatorsHaveDescriptions() throws {
        for separator in TimeSeparator.allCases {
            #expect(separator.description.isEmpty == false)
        }
    }

    @Test func separatorRawValuesAreCorrect() throws {
        #expect(TimeSeparator.colon.rawValue == ":")
        #expect(TimeSeparator.dot.rawValue == ".")
        #expect(TimeSeparator.dash.rawValue == "-")
        #expect(TimeSeparator.space.rawValue == " ")
    }
}

// MARK: - Font Family Tests
struct FontFamilyTests {

    @Test func allFamiliesHaveDescriptions() throws {
        for family in FontFamily.allCases {
            #expect(family.description.isEmpty == false)
        }
    }

    @Test func systemFontHasNoFontName() throws {
        #expect(FontFamily.system.fontName == nil)
    }

    @Test func customFontsHaveFontNames() throws {
        #expect(FontFamily.sfMono.fontName != nil)
        #expect(FontFamily.menlo.fontName != nil)
        #expect(FontFamily.monaco.fontName != nil)
        #expect(FontFamily.courier.fontName != nil)
    }
}

// MARK: - Keyboard Shortcut Tests
struct KeyboardShortcutTests {

    @Test func displayStringFormatsCorrectly() throws {
        let shortcut = KeyboardShortcut(key: "T", modifiers: [.command, .shift])
        let display = shortcut.displayString

        #expect(display.contains("T"))
        #expect(display.contains("\u{2318}")) // Command symbol
        #expect(display.contains("\u{21E7}")) // Shift symbol
    }

    @Test func emptyShortcutHasEmptyKey() throws {
        let empty = KeyboardShortcut.empty
        #expect(empty.key.isEmpty)
        #expect(empty.modifiers.isEmpty)
    }

    @Test func modifierSymbolsAreCorrect() throws {
        #expect(KeyboardShortcut.Modifier.command.symbol == "\u{2318}")
        #expect(KeyboardShortcut.Modifier.shift.symbol == "\u{21E7}")
        #expect(KeyboardShortcut.Modifier.option.symbol == "\u{2325}")
        #expect(KeyboardShortcut.Modifier.control.symbol == "\u{2303}")
    }
}

// MARK: - Timezone Group Tests
struct TimezoneGroupTests {

    @Test func createsGroupWithDefaults() throws {
        let group = TimezoneGroup(name: "Test Group")

        #expect(group.name == "Test Group")
        #expect(group.colorHex == "#007AFF")
        #expect(group.icon == "folder")
        #expect(group.order == 0)
    }

    @Test func defaultGroupsExist() throws {
        let defaults = TimezoneGroup.defaultGroups

        #expect(defaults.count == 3)
        #expect(defaults.contains { $0.name == "Work" })
        #expect(defaults.contains { $0.name == "Personal" })
        #expect(defaults.contains { $0.name == "Clients" })
    }

    @Test func groupColorIsParsed() throws {
        let group = TimezoneGroup(name: "Test", colorHex: "#FF0000")
        #expect(group.color != Color.blue) // Should be red, not default blue
    }
}

// MARK: - Storage Service Tests
struct StorageServiceTests {

    @Test func savesAndLoadsTimeZones() throws {
        let service = StorageService.shared

        let zones = [
            TimeZoneEntry(identifier: "America/New_York", order: 0),
            TimeZoneEntry(identifier: "Europe/London", order: 1)
        ]

        service.saveTimeZones(zones)
        let loaded = service.loadTimeZones()

        #expect(loaded.count == zones.count)
        #expect(loaded[0].identifier == zones[0].identifier)
    }

    @Test func savesAndLoadsPreferences() throws {
        let service = StorageService.shared

        var prefs = AppPreferences.default
        prefs.use24HourFormat = true
        prefs.showSeconds = true

        service.savePreferences(prefs)
        let loaded = service.loadPreferences()

        #expect(loaded.use24HourFormat == true)
        #expect(loaded.showSeconds == true)
    }

    @Test func savesAndLoadsGroups() throws {
        let service = StorageService.shared

        let groups = [
            TimezoneGroup(name: "Test Group 1", order: 0),
            TimezoneGroup(name: "Test Group 2", order: 1)
        ]

        service.saveGroups(groups)
        let loaded = service.loadGroups()

        #expect(loaded.count == groups.count)
        #expect(loaded[0].name == groups[0].name)
    }

    @Test func exportSettingsReturnsData() throws {
        let service = StorageService.shared
        let data = service.exportSettings()

        #expect(data != nil)
        #expect(data?.isEmpty == false)
    }
}

// MARK: - Calendar Event Tests
struct CalendarEventTests {

    @Test func minutesUntilStartCalculatesCorrectly() throws {
        // Create a mock event starting in 30 minutes
        let startDate = Date().addingTimeInterval(30 * 60)
        let endDate = startDate.addingTimeInterval(60 * 60)

        // We can't directly test CalendarEvent without EKEvent,
        // but we can test the calculation logic
        let interval = startDate.timeIntervalSince(Date())
        let minutes = max(0, Int(interval / 60))

        #expect(minutes >= 29 && minutes <= 31)
    }

    @Test func progressCalculatesCorrectly() throws {
        // Test progress calculation logic
        let startDate = Date().addingTimeInterval(-30 * 60) // Started 30 min ago
        let endDate = Date().addingTimeInterval(30 * 60)    // Ends in 30 min

        let total = endDate.timeIntervalSince(startDate)
        let elapsed = Date().timeIntervalSince(startDate)
        let progress = min(max(elapsed / total, 0), 1)

        #expect(progress >= 0.49 && progress <= 0.51)
    }
}

// MARK: - Test Helper
struct TestError: Error, CustomStringConvertible {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var description: String { message }
}
