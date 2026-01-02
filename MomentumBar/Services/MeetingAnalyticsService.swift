//
//  MeetingAnalyticsService.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation

// MARK: - Meeting Record
struct MeetingRecord: Identifiable, Codable {
    let id: UUID
    let title: String
    let startTime: Date
    let endTime: Date
    let calendarName: String
    let hasMeetingLink: Bool
    let platform: String?

    init(from event: CalendarEvent) {
        self.id = UUID()
        self.title = event.title
        self.startTime = event.startDate
        self.endTime = event.endDate
        self.calendarName = event.calendarTitle
        self.hasMeetingLink = event.meetingLink != nil
        self.platform = event.meetingLink?.platform.rawValue
    }

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var durationMinutes: Int {
        Int(duration / 60)
    }

    var hourOfDay: Int {
        Calendar.current.component(.hour, from: startTime)
    }

    var dayOfWeek: Int {
        Calendar.current.component(.weekday, from: startTime)
    }
}

// MARK: - Daily Stats
struct DailyMeetingStats: Codable, Identifiable {
    let date: Date
    var totalMeetings: Int
    var totalMinutes: Int
    var meetingsByHour: [Int: Int] // hour -> count

    var id: Date { date }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: date)
    }

    var formattedDuration: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Weekly Summary
struct WeeklyMeetingSummary {
    let weekStart: Date
    let weekEnd: Date
    let totalMeetings: Int
    let totalMinutes: Int
    let averageMeetingsPerDay: Double
    let busiestDay: String
    let busiestHour: Int
    let meetingFreeBlocks: [MeetingFreeBlock]
    let dailyStats: [DailyMeetingStats]

    var formattedTotalTime: String {
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var busiestHourFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: busiestHour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Meeting Free Block
struct MeetingFreeBlock: Identifiable {
    let id = UUID()
    let date: Date
    let startHour: Int
    let endHour: Int

    var duration: Int {
        endHour - startHour
    }

    var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let start = Calendar.current.date(bySettingHour: startHour, minute: 0, second: 0, of: date) ?? date
        let end = Calendar.current.date(bySettingHour: endHour, minute: 0, second: 0, of: date) ?? date
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
}

// MARK: - Meeting Analytics Service
@MainActor
@Observable
final class MeetingAnalyticsService {
    static let shared = MeetingAnalyticsService()

    // Data
    private(set) var meetingRecords: [MeetingRecord] = []
    private(set) var dailyStats: [DailyMeetingStats] = []

    // Computed
    var weeklySummary: WeeklyMeetingSummary? {
        calculateWeeklySummary()
    }

    var todayStats: DailyMeetingStats? {
        let calendar = Calendar.current
        return dailyStats.first { calendar.isDateInToday($0.date) }
    }

    private let storageKey = "com.momentumbar.meetingAnalytics"
    private let maxStorageDays = 90 // Keep 90 days of data

    private init() {
        loadData()
    }

    // MARK: - Recording

    /// Record a meeting that has ended
    func recordMeeting(from event: CalendarEvent) {
        guard !event.isAllDay else { return }
        guard event.isPast || event.isOngoing else { return }

        // Check if already recorded
        let isDuplicate = meetingRecords.contains {
            $0.title == event.title &&
            Calendar.current.isDate($0.startTime, equalTo: event.startDate, toGranularity: .minute)
        }

        guard !isDuplicate else { return }

        let record = MeetingRecord(from: event)
        meetingRecords.append(record)
        updateDailyStats(for: record)
        saveData()
    }

    /// Record multiple meetings from calendar events
    func recordMeetings(from events: [CalendarEvent]) {
        for event in events {
            recordMeeting(from: event)
        }
    }

    // MARK: - Daily Stats

    private func updateDailyStats(for record: MeetingRecord) {
        let calendar = Calendar.current
        let dateOnly = calendar.startOfDay(for: record.startTime)

        if let index = dailyStats.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: dateOnly) }) {
            dailyStats[index].totalMeetings += 1
            dailyStats[index].totalMinutes += record.durationMinutes
            dailyStats[index].meetingsByHour[record.hourOfDay, default: 0] += 1
        } else {
            var newStats = DailyMeetingStats(
                date: dateOnly,
                totalMeetings: 1,
                totalMinutes: record.durationMinutes,
                meetingsByHour: [:]
            )
            newStats.meetingsByHour[record.hourOfDay] = 1
            dailyStats.append(newStats)
            dailyStats.sort { $0.date > $1.date }
        }
    }

    // MARK: - Weekly Summary

    private func calculateWeeklySummary() -> WeeklyMeetingSummary? {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return nil
        }
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return nil
        }

        let weekStats = dailyStats.filter { stat in
            stat.date >= weekStart && stat.date <= weekEnd
        }

        guard !weekStats.isEmpty else {
            return WeeklyMeetingSummary(
                weekStart: weekStart,
                weekEnd: weekEnd,
                totalMeetings: 0,
                totalMinutes: 0,
                averageMeetingsPerDay: 0,
                busiestDay: "N/A",
                busiestHour: 9,
                meetingFreeBlocks: findMeetingFreeBlocks(in: weekStats),
                dailyStats: weekStats
            )
        }

        let totalMeetings = weekStats.reduce(0) { $0 + $1.totalMeetings }
        let totalMinutes = weekStats.reduce(0) { $0 + $1.totalMinutes }
        let averagePerDay = Double(totalMeetings) / Double(max(weekStats.count, 1))

        // Find busiest day
        let busiestDayStats = weekStats.max { $0.totalMeetings < $1.totalMeetings }
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let busiestDay = busiestDayStats.map { dayFormatter.string(from: $0.date) } ?? "N/A"

        // Find busiest hour
        var hourCounts: [Int: Int] = [:]
        for stat in weekStats {
            for (hour, count) in stat.meetingsByHour {
                hourCounts[hour, default: 0] += count
            }
        }
        let busiestHour = hourCounts.max { $0.value < $1.value }?.key ?? 9

        return WeeklyMeetingSummary(
            weekStart: weekStart,
            weekEnd: weekEnd,
            totalMeetings: totalMeetings,
            totalMinutes: totalMinutes,
            averageMeetingsPerDay: averagePerDay,
            busiestDay: busiestDay,
            busiestHour: busiestHour,
            meetingFreeBlocks: findMeetingFreeBlocks(in: weekStats),
            dailyStats: weekStats.sorted { $0.date < $1.date }
        )
    }

    // MARK: - Meeting Free Blocks

    private func findMeetingFreeBlocks(in stats: [DailyMeetingStats]) -> [MeetingFreeBlock] {
        var freeBlocks: [MeetingFreeBlock] = []
        let workHours = 9...17 // 9 AM to 5 PM

        for stat in stats {
            var freeStart: Int? = nil

            for hour in workHours {
                if stat.meetingsByHour[hour] == nil || stat.meetingsByHour[hour] == 0 {
                    if freeStart == nil {
                        freeStart = hour
                    }
                } else {
                    if let start = freeStart, hour - start >= 2 {
                        freeBlocks.append(MeetingFreeBlock(
                            date: stat.date,
                            startHour: start,
                            endHour: hour
                        ))
                    }
                    freeStart = nil
                }
            }

            // Check for trailing free block
            if let start = freeStart, 18 - start >= 2 {
                freeBlocks.append(MeetingFreeBlock(
                    date: stat.date,
                    startHour: start,
                    endHour: 18
                ))
            }
        }

        return freeBlocks
    }

    // MARK: - Insights

    var averageMeetingDuration: Int {
        guard !meetingRecords.isEmpty else { return 0 }
        let total = meetingRecords.reduce(0) { $0 + $1.durationMinutes }
        return total / meetingRecords.count
    }

    var mostUsedPlatform: String? {
        let platforms = meetingRecords.compactMap { $0.platform }
        guard !platforms.isEmpty else { return nil }

        var counts: [String: Int] = [:]
        for platform in platforms {
            counts[platform, default: 0] += 1
        }

        return counts.max { $0.value < $1.value }?.key
    }

    var meetingsByDayOfWeek: [Int: Int] {
        var counts: [Int: Int] = [:]
        for record in meetingRecords {
            counts[record.dayOfWeek, default: 0] += 1
        }
        return counts
    }

    // MARK: - Persistence

    private func loadData() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }

        do {
            let decoder = JSONDecoder()
            let stored = try decoder.decode(StoredAnalytics.self, from: data)
            meetingRecords = stored.records
            dailyStats = stored.dailyStats

            // Clean old data
            cleanOldData()
        } catch {
            print("Failed to load meeting analytics: \(error)")
        }
    }

    private func saveData() {
        do {
            let encoder = JSONEncoder()
            let stored = StoredAnalytics(records: meetingRecords, dailyStats: dailyStats)
            let data = try encoder.encode(stored)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save meeting analytics: \(error)")
        }
    }

    private func cleanOldData() {
        let calendar = Calendar.current
        guard let cutoffDate = calendar.date(byAdding: .day, value: -maxStorageDays, to: Date()) else { return }

        meetingRecords.removeAll { $0.startTime < cutoffDate }
        dailyStats.removeAll { $0.date < cutoffDate }
    }

    /// Clear all analytics data
    func clearAllData() {
        meetingRecords.removeAll()
        dailyStats.removeAll()
        saveData()
    }
}

// MARK: - Storage Model
private struct StoredAnalytics: Codable {
    let records: [MeetingRecord]
    let dailyStats: [DailyMeetingStats]
}
