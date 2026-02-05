//
//  StorageService.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation
import WidgetKit

// MARK: - Shared Widget Models

/// Timezone data shared with widget via App Group
struct WidgetTimeZoneEntry: Codable {
    let id: String
    let identifier: String
    let customName: String?
    let order: Int
}

/// Pomodoro state shared with widget via App Group
struct SharedPomodoroState: Codable {
    let state: String              // PomodoroState raw value
    let timeRemaining: TimeInterval
    let totalDuration: TimeInterval
    let completedSessions: Int
    let totalSessionsToday: Int
    let sessionsUntilLongBreak: Int
    let lastUpdated: Date
    let endTime: Date?             // When timer will complete (for widget timeline)

    /// Check if state is stale (older than 2 seconds for running timers)
    var isStale: Bool {
        guard state == "working" || state == "shortBreak" || state == "longBreak" else {
            return false
        }
        return Date().timeIntervalSince(lastUpdated) > 2
    }
}

/// Commands from widget to main app
enum WidgetPomodoroCommand: String, Codable {
    case start
    case pause
    case stop
    case skip
}

struct WidgetCommand: Codable {
    let command: WidgetPomodoroCommand
    let timestamp: Date
}

final class StorageService {
    static let shared = StorageService()

    private let defaults = UserDefaults.standard
    private let sharedDefaults: UserDefaults?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Whether the app group is available (requires proper provisioning)
    private(set) var isAppGroupAvailable: Bool = false

    private enum Keys {
        static let timeZones = "com.momentumbar.timeZones"
        static let preferences = "com.momentumbar.preferences"
        static let groups = "com.momentumbar.groups"
        static let lastCalendarSync = "com.momentumbar.lastCalendarSync"
        // Widget shared keys
        static let sharedTimeZones = "com.momentumbar.timezones"
        static let sharedUse24Hour = "com.momentumbar.use24HourFormat"
        // Pomodoro widget keys
        static let sharedPomodoroState = "com.momentumbar.pomodoro.state"
        static let sharedPomodoroCommand = "com.momentumbar.pomodoro.command"
    }

    // MARK: - App Group Suite Name
    static let appGroupSuite = "group.com.momentumbar.shared"

    private init() {
        // Disable app group until proper Apple Developer provisioning is in place
        // This prevents SQLite errors during development
        self.sharedDefaults = nil
        self.isAppGroupAvailable = false
    }

    // MARK: - Time Zones
    func saveTimeZones(_ zones: [TimeZoneEntry]) {
        do {
            let data = try encoder.encode(zones)
            defaults.set(data, forKey: Keys.timeZones)

            // Sync to shared App Group for widget
            syncTimeZonesToWidget(zones)
        } catch {
            print("Failed to save time zones: \(error)")
        }
    }

    // MARK: - Widget Sync
    private func syncTimeZonesToWidget(_ zones: [TimeZoneEntry]) {
        guard isAppGroupAvailable, let sharedDefaults = sharedDefaults else { return }

        // Convert to widget-compatible format
        let widgetEntries = zones.map { entry in
            WidgetTimeZoneEntry(
                id: entry.id.uuidString,
                identifier: entry.identifier,
                customName: entry.customName,
                order: entry.order
            )
        }

        do {
            let data = try encoder.encode(widgetEntries)
            sharedDefaults.set(data, forKey: Keys.sharedTimeZones)

            // Also sync preferences
            let preferences = loadPreferences()
            sharedDefaults.set(preferences.use24HourFormat, forKey: Keys.sharedUse24Hour)

            // Tell WidgetKit to reload
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Failed to sync timezones to widget: \(error)")
        }
    }

    /// Call this to force a widget refresh
    func refreshWidget() {
        syncTimeZonesToWidget(loadTimeZones())
    }

    func loadTimeZones() -> [TimeZoneEntry] {
        guard let data = defaults.data(forKey: Keys.timeZones) else {
            return []
        }

        do {
            return try decoder.decode([TimeZoneEntry].self, from: data)
        } catch {
            print("Failed to load time zones: \(error)")
            return []
        }
    }

    // MARK: - Preferences
    func savePreferences(_ preferences: AppPreferences) {
        do {
            let data = try encoder.encode(preferences)
            defaults.set(data, forKey: Keys.preferences)
        } catch {
            print("Failed to save preferences: \(error)")
        }
    }

    func loadPreferences() -> AppPreferences {
        guard let data = defaults.data(forKey: Keys.preferences) else {
            return .default
        }

        do {
            return try decoder.decode(AppPreferences.self, from: data)
        } catch {
            print("Failed to load preferences: \(error)")
            return .default
        }
    }

    // MARK: - Groups
    func saveGroups(_ groups: [TimezoneGroup]) {
        do {
            let data = try encoder.encode(groups)
            defaults.set(data, forKey: Keys.groups)
        } catch {
            print("Failed to save groups: \(error)")
        }
    }

    func loadGroups() -> [TimezoneGroup] {
        guard let data = defaults.data(forKey: Keys.groups) else {
            return []
        }

        do {
            return try decoder.decode([TimezoneGroup].self, from: data)
        } catch {
            print("Failed to load groups: \(error)")
            return []
        }
    }

    // MARK: - Calendar
    func saveLastCalendarSync(_ date: Date) {
        defaults.set(date, forKey: Keys.lastCalendarSync)
    }

    func loadLastCalendarSync() -> Date? {
        return defaults.object(forKey: Keys.lastCalendarSync) as? Date
    }

    // MARK: - Reset
    func resetAll() {
        defaults.removeObject(forKey: Keys.timeZones)
        defaults.removeObject(forKey: Keys.preferences)
        defaults.removeObject(forKey: Keys.groups)
        defaults.removeObject(forKey: Keys.lastCalendarSync)
    }

    // MARK: - Export/Import
    func exportSettings() -> Data? {
        struct ExportData: Codable {
            let timeZones: [TimeZoneEntry]
            let preferences: AppPreferences
            let groups: [TimezoneGroup]
            let exportDate: Date
        }

        let exportData = ExportData(
            timeZones: loadTimeZones(),
            preferences: loadPreferences(),
            groups: loadGroups(),
            exportDate: Date()
        )

        return try? encoder.encode(exportData)
    }

    func importSettings(from data: Data) -> Bool {
        struct ExportData: Codable {
            let timeZones: [TimeZoneEntry]
            let preferences: AppPreferences
            let groups: [TimezoneGroup]?
            let exportDate: Date
        }

        do {
            let importData = try decoder.decode(ExportData.self, from: data)
            saveTimeZones(importData.timeZones)
            savePreferences(importData.preferences)
            if let groups = importData.groups {
                saveGroups(groups)
            }
            return true
        } catch {
            print("Failed to import settings: \(error)")
            return false
        }
    }

    // MARK: - Pomodoro Widget Sync

    /// Save pomodoro state to shared App Group for widget
    func savePomodoroState(_ state: SharedPomodoroState) {
        guard isAppGroupAvailable, let sharedDefaults = sharedDefaults else { return }

        do {
            let data = try encoder.encode(state)
            sharedDefaults.set(data, forKey: Keys.sharedPomodoroState)

            // Reload pomodoro widget
            WidgetCenter.shared.reloadTimelines(ofKind: "PomodoroWidget")
        } catch {
            print("Failed to save pomodoro state: \(error)")
        }
    }

    /// Load pomodoro state from shared App Group
    func loadPomodoroState() -> SharedPomodoroState? {
        guard isAppGroupAvailable,
              let sharedDefaults = sharedDefaults,
              let data = sharedDefaults.data(forKey: Keys.sharedPomodoroState) else {
            return nil
        }

        return try? decoder.decode(SharedPomodoroState.self, from: data)
    }

    /// Save a command from widget to be processed by main app
    func savePomodoroCommand(_ command: WidgetPomodoroCommand) {
        guard isAppGroupAvailable, let sharedDefaults = sharedDefaults else { return }

        let widgetCommand = WidgetCommand(command: command, timestamp: Date())

        do {
            let data = try encoder.encode(widgetCommand)
            sharedDefaults.set(data, forKey: Keys.sharedPomodoroCommand)
        } catch {
            print("Failed to save pomodoro command: \(error)")
        }
    }

    /// Load and clear pending command from widget
    func loadAndClearPomodoroCommand() -> WidgetCommand? {
        guard isAppGroupAvailable,
              let sharedDefaults = sharedDefaults,
              let data = sharedDefaults.data(forKey: Keys.sharedPomodoroCommand) else {
            return nil
        }

        // Clear the command
        sharedDefaults.removeObject(forKey: Keys.sharedPomodoroCommand)

        guard let command = try? decoder.decode(WidgetCommand.self, from: data) else {
            return nil
        }

        // Only return if command is recent (within last 5 seconds)
        if Date().timeIntervalSince(command.timestamp) < 5 {
            return command
        }

        return nil
    }
}
