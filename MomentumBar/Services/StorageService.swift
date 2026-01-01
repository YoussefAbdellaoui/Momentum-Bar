//
//  StorageService.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation

final class StorageService {
    static let shared = StorageService()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Keys {
        static let timeZones = "com.momentumbar.timeZones"
        static let preferences = "com.momentumbar.preferences"
        static let lastCalendarSync = "com.momentumbar.lastCalendarSync"
    }

    private init() {}

    // MARK: - Time Zones
    func saveTimeZones(_ zones: [TimeZoneEntry]) {
        do {
            let data = try encoder.encode(zones)
            defaults.set(data, forKey: Keys.timeZones)
        } catch {
            print("Failed to save time zones: \(error)")
        }
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
        defaults.removeObject(forKey: Keys.lastCalendarSync)
    }

    // MARK: - Export/Import
    func exportSettings() -> Data? {
        struct ExportData: Codable {
            let timeZones: [TimeZoneEntry]
            let preferences: AppPreferences
            let exportDate: Date
        }

        let exportData = ExportData(
            timeZones: loadTimeZones(),
            preferences: loadPreferences(),
            exportDate: Date()
        )

        return try? encoder.encode(exportData)
    }

    func importSettings(from data: Data) -> Bool {
        struct ExportData: Codable {
            let timeZones: [TimeZoneEntry]
            let preferences: AppPreferences
            let exportDate: Date
        }

        do {
            let importData = try decoder.decode(ExportData.self, from: data)
            saveTimeZones(importData.timeZones)
            savePreferences(importData.preferences)
            return true
        } catch {
            print("Failed to import settings: \(error)")
            return false
        }
    }
}
