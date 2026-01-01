//
//  AppPreferences.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation

struct AppPreferences: Codable, Equatable {
    // Time Format
    var use24HourFormat: Bool = false
    var showSeconds: Bool = false

    // Display
    var showDayNightIndicator: Bool = true
    var menuBarDisplayMode: MenuBarDisplayMode = .icon

    // Calendar
    var selectedCalendarIDs: Set<String> = []
    var meetingReminderMinutes: Int = 10
    var showMeetingReminders: Bool = true

    // Startup
    var launchAtLogin: Bool = false

    // Time Scroller
    var defaultScrollerRange: Int = 24 // hours

    static let `default` = AppPreferences()
}

enum MenuBarDisplayMode: String, Codable, CaseIterable {
    case icon = "icon"
    case time = "time"
    case iconAndTime = "both"

    var description: String {
        switch self {
        case .icon: return "Icon only"
        case .time: return "Time only"
        case .iconAndTime: return "Icon and time"
        }
    }
}

enum TimeDisplayMode: String, Codable, CaseIterable {
    case cityName = "city"
    case abbreviation = "abbreviation"
    case offset = "offset"
    case custom = "custom"

    var description: String {
        switch self {
        case .cityName: return "City name (Tokyo: 3:45 PM)"
        case .abbreviation: return "Abbreviation (JST: 3:45 PM)"
        case .offset: return "UTC offset (+09:00: 3:45 PM)"
        case .custom: return "Custom label"
        }
    }
}
