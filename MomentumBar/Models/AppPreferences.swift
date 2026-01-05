//
//  AppPreferences.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation
import SwiftUI

struct AppPreferences: Codable, Equatable {
    // Time Format
    var use24HourFormat: Bool = false
    var showSeconds: Bool = false
    var timeSeparator: TimeSeparator = .colon

    // Font Customization
    var fontFamily: FontFamily = .system
    var fontWeight: FontWeightOption = .medium
    var timeAlignment: TimeAlignment = .trailing

    // Display
    var showDayNightIndicator: Bool = true
    var menuBarDisplayMode: MenuBarDisplayMode = .icon

    // Day/Night Detection
    var useAccurateSunriseSunset: Bool = true
    var defaultLatitude: Double? = nil  // User's default location for sunrise/sunset
    var defaultLongitude: Double? = nil

    // Calendar
    var selectedCalendarIDs: Set<String> = []
    var meetingReminderMinutes: Int = 10
    var showMeetingReminders: Bool = true

    // Buffer Time Warnings
    var showBufferWarnings: Bool = true
    var minimumBufferMinutes: Int = 10

    // Menu Bar
    var showMeetingBadge: Bool = true
    var showNextMeetingTime: Bool = false

    // Startup
    var launchAtLogin: Bool = false
    var hideDockIcon: Bool = false

    // Window Behavior
    var keepPopoverPinned: Bool = false

    // Keyboard Shortcuts
    var togglePopoverShortcut: KeyboardShortcut = .init(key: "T", modifiers: [.command, .shift])
    var addTimeZoneShortcut: KeyboardShortcut = .init(key: "N", modifiers: [.command])
    var openSettingsShortcut: KeyboardShortcut = .init(key: ",", modifiers: [.command])

    // Theme
    var selectedThemeID: UUID? = nil

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

// MARK: - Time Separator
enum TimeSeparator: String, Codable, CaseIterable {
    case colon = ":"
    case dot = "."
    case dash = "-"
    case space = " "

    var description: String {
        switch self {
        case .colon: return "Colon (3:45)"
        case .dot: return "Dot (3.45)"
        case .dash: return "Dash (3-45)"
        case .space: return "Space (3 45)"
        }
    }
}

// MARK: - Font Family
enum FontFamily: String, Codable, CaseIterable {
    case system = "system"
    case sfMono = "SF Mono"
    case menlo = "Menlo"
    case monaco = "Monaco"
    case courier = "Courier New"

    var description: String {
        switch self {
        case .system: return "System (Default)"
        case .sfMono: return "SF Mono"
        case .menlo: return "Menlo"
        case .monaco: return "Monaco"
        case .courier: return "Courier New"
        }
    }

    var fontName: String? {
        switch self {
        case .system: return nil
        case .sfMono: return "SFMono-Regular"
        case .menlo: return "Menlo"
        case .monaco: return "Monaco"
        case .courier: return "Courier New"
        }
    }
}

// MARK: - Font Weight
enum FontWeightOption: String, Codable, CaseIterable {
    case light = "light"
    case regular = "regular"
    case medium = "medium"
    case semibold = "semibold"
    case bold = "bold"

    var description: String {
        switch self {
        case .light: return "Light"
        case .regular: return "Regular"
        case .medium: return "Medium"
        case .semibold: return "Semibold"
        case .bold: return "Bold"
        }
    }

    var weight: Font.Weight {
        switch self {
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }
}

// MARK: - Time Alignment
enum TimeAlignment: String, Codable, CaseIterable {
    case leading = "leading"
    case center = "center"
    case trailing = "trailing"

    var description: String {
        switch self {
        case .leading: return "Left"
        case .center: return "Center"
        case .trailing: return "Right"
        }
    }

    var alignment: HorizontalAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }

    var textAlignment: TextAlignment {
        switch self {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

// MARK: - AppStorage Conformance
extension TimeSeparator: RawRepresentable {
    public init?(rawValue: String) {
        switch rawValue {
        case ":": self = .colon
        case ".": self = .dot
        case "-": self = .dash
        case " ": self = .space
        default: return nil
        }
    }
}

extension FontFamily: RawRepresentable {
    public init?(rawValue: String) {
        switch rawValue {
        case "system": self = .system
        case "SF Mono": self = .sfMono
        case "Menlo": self = .menlo
        case "Monaco": self = .monaco
        case "Courier New": self = .courier
        default: return nil
        }
    }
}

extension FontWeightOption: RawRepresentable {
    public init?(rawValue: String) {
        switch rawValue {
        case "light": self = .light
        case "regular": self = .regular
        case "medium": self = .medium
        case "semibold": self = .semibold
        case "bold": self = .bold
        default: return nil
        }
    }
}

extension TimeAlignment: RawRepresentable {
    public init?(rawValue: String) {
        switch rawValue {
        case "leading": self = .leading
        case "center": self = .center
        case "trailing": self = .trailing
        default: return nil
        }
    }
}

// MARK: - Keyboard Shortcut
struct KeyboardShortcut: Codable, Equatable {
    var key: String
    var modifiers: Set<Modifier>

    enum Modifier: String, Codable, CaseIterable {
        case command = "command"
        case shift = "shift"
        case option = "option"
        case control = "control"

        var symbol: String {
            switch self {
            case .command: return "\u{2318}"
            case .shift: return "\u{21E7}"
            case .option: return "\u{2325}"
            case .control: return "\u{2303}"
            }
        }
    }

    var displayString: String {
        let modifierSymbols = Modifier.allCases
            .filter { modifiers.contains($0) }
            .map { $0.symbol }
            .joined()
        return modifierSymbols + key.uppercased()
    }

    static let empty = KeyboardShortcut(key: "", modifiers: [])
}
