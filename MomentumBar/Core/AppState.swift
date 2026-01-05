//
//  AppState.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation
import SwiftUI
import Combine

@Observable
final class AppState {
    // MARK: - Singleton
    static let shared = AppState()

    // MARK: - Time Zones
    var timeZones: [TimeZoneEntry] = [] {
        didSet {
            StorageService.shared.saveTimeZones(timeZones)
        }
    }

    // MARK: - Timezone Groups
    var groups: [TimezoneGroup] = [] {
        didSet {
            StorageService.shared.saveGroups(groups)
        }
    }

    var selectedGroupID: UUID? = nil

    var filteredTimeZones: [TimeZoneEntry] {
        guard let groupID = selectedGroupID else {
            return timeZones
        }
        return timeZones.filter { $0.groupID == groupID }
    }

    var ungroupedTimeZones: [TimeZoneEntry] {
        timeZones.filter { $0.groupID == nil }
    }

    func timeZones(for group: TimezoneGroup) -> [TimeZoneEntry] {
        timeZones.filter { $0.groupID == group.id }
    }

    // MARK: - Preferences
    var preferences: AppPreferences = .default {
        didSet {
            StorageService.shared.savePreferences(preferences)
        }
    }

    // MARK: - Current Time (updated every second)
    var currentTime: Date = Date()

    // MARK: - Time Scroller
    var previewOffsetHours: Double = 0

    var previewTime: Date {
        currentTime.addingTimeInterval(previewOffsetHours * 3600)
    }

    var isPreviewActive: Bool {
        previewOffsetHours != 0
    }

    // MARK: - Calendar Events
    var events: [CalendarEvent] = []
    var calendarAccessGranted: Bool = false

    // MARK: - UI State
    var isAddingTimeZone: Bool = false
    var selectedTimeZone: TimeZoneEntry?

    // MARK: - Timer
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    private init() {
        loadSavedData()
        startTimer()
    }

    private func loadSavedData() {
        timeZones = StorageService.shared.loadTimeZones()
        preferences = StorageService.shared.loadPreferences()
        groups = StorageService.shared.loadGroups()

        // Add local timezone if no timezones saved
        if timeZones.isEmpty {
            addLocalTimeZone()
        }
    }

    private func addLocalTimeZone() {
        let localZone = TimeZoneEntry(
            identifier: TimeZone.current.identifier,
            customName: "Local",
            order: 0
        )
        timeZones.append(localZone)
    }

    // MARK: - Timer Management
    func startTimer() {
        stopTimer()

        // Align to the next second
        let now = Date()
        let nextSecond = ceil(now.timeIntervalSinceReferenceDate)
        let delay = nextSecond - now.timeIntervalSinceReferenceDate

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.currentTime = Date()
            self?.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.currentTime = Date()
            }
            if let timer = self?.timer {
                RunLoop.current.add(timer, forMode: .common)
            }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Time Zone Management
    func addTimeZone(_ entry: TimeZoneEntry) {
        var newEntry = entry
        newEntry.order = timeZones.count
        timeZones.append(newEntry)
    }

    func removeTimeZone(at offsets: IndexSet) {
        timeZones.remove(atOffsets: offsets)
        reorderTimeZones()
    }

    func moveTimeZone(from source: IndexSet, to destination: Int) {
        timeZones.move(fromOffsets: source, toOffset: destination)
        reorderTimeZones()
    }

    private func reorderTimeZones() {
        for (index, _) in timeZones.enumerated() {
            timeZones[index].order = index
        }
    }

    func updateTimeZone(_ entry: TimeZoneEntry) {
        if let index = timeZones.firstIndex(where: { $0.id == entry.id }) {
            timeZones[index] = entry
        }
    }

    // MARK: - Time Formatting
    func formattedTime(for zone: TimeZone, time: Date? = nil) -> String {
        let displayTime = time ?? currentTime
        let formatter = DateFormatter()
        formatter.timeZone = zone

        let separator = preferences.timeSeparator.rawValue

        if preferences.use24HourFormat {
            if preferences.showSeconds {
                formatter.dateFormat = "HH'\(separator)'mm'\(separator)'ss"
            } else {
                formatter.dateFormat = "HH'\(separator)'mm"
            }
        } else {
            if preferences.showSeconds {
                formatter.dateFormat = "h'\(separator)'mm'\(separator)'ss a"
            } else {
                formatter.dateFormat = "h'\(separator)'mm a"
            }
        }

        return formatter.string(from: displayTime)
    }

    func formattedDate(for zone: TimeZone, time: Date? = nil) -> String {
        let displayTime = time ?? currentTime
        let formatter = DateFormatter()
        formatter.timeZone = zone
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: displayTime)
    }

    // MARK: - Day/Night Detection
    func isDaytime(for zone: TimeZone, at time: Date? = nil) -> Bool {
        let displayTime = time ?? currentTime

        // Use accurate sunrise/sunset if enabled
        if preferences.useAccurateSunriseSunset {
            return SunriseSunsetService.shared.isDaytime(for: zone, at: displayTime)
        }

        // Fallback to simple approximation: 6 AM - 6 PM is daytime
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: zone, from: displayTime)
        let hour = components.hour ?? 12
        return hour >= 6 && hour < 18
    }

    /// Get sunrise and sunset times for a timezone
    func getSunriseSunset(for zone: TimeZone, on date: Date? = nil) -> (sunrise: Date, sunset: Date)? {
        let displayDate = date ?? currentTime
        return SunriseSunsetService.shared.getSunriseSunset(for: zone, on: displayDate)
    }

    var awakeCount: Int {
        timeZones.filter { entry in
            guard let tz = entry.timeZone else { return false }
            return isDaytime(for: tz)
        }.count
    }

    var asleepCount: Int {
        timeZones.count - awakeCount
    }

    // MARK: - Preview Time
    func resetPreview() {
        previewOffsetHours = 0
    }
}
