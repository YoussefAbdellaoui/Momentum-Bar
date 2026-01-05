//
//  MeetingAnalyticsView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI

struct MeetingAnalyticsView: View {
    @State private var analyticsService = MeetingAnalyticsService.shared
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Meeting Analytics")
                    .font(.headline)
                Spacer()
                Picker("", selection: $selectedTab) {
                    Text("Week").tag(0)
                    Text("Insights").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }
            .padding()

            Divider()

            if selectedTab == 0 {
                weeklyView
            } else {
                insightsView
            }
        }
    }

    // MARK: - Weekly View
    private var weeklyView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let summary = analyticsService.weeklySummary {
                    // Summary Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(
                            title: "Total Meetings",
                            value: "\(summary.totalMeetings)",
                            icon: "calendar",
                            color: .blue
                        )

                        StatCard(
                            title: "Time in Meetings",
                            value: summary.formattedTotalTime,
                            icon: "clock",
                            color: .orange
                        )

                        StatCard(
                            title: "Avg per Day",
                            value: String(format: "%.1f", summary.averageMeetingsPerDay),
                            icon: "chart.bar",
                            color: .green
                        )

                        StatCard(
                            title: "Busiest Hour",
                            value: summary.busiestHourFormatted,
                            icon: "sun.max",
                            color: .yellow
                        )
                    }

                    // Daily Breakdown
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily Breakdown")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        if summary.dailyStats.isEmpty {
                            Text("No meeting data for this week")
                                .foregroundStyle(.tertiary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(summary.dailyStats) { stat in
                                DailyStatRow(stat: stat)
                            }
                        }
                    }
                    .padding()
                    .background(Color.primary.opacity(0.03))
                    .cornerRadius(12)

                    // Meeting Free Blocks
                    if !summary.meetingFreeBlocks.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "leaf.fill")
                                    .foregroundStyle(.green)
                                Text("Focus Time Opportunities")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }

                            Text("2+ hour meeting-free blocks during work hours")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ForEach(summary.meetingFreeBlocks) { block in
                                FreeBlockRow(block: block)
                            }
                        }
                        .padding()
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(12)
                    }
                } else {
                    emptyState
                }
            }
            .padding()
        }
    }

    // MARK: - Insights View
    private var insightsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Average Meeting Duration
                InsightCard(
                    icon: "timer",
                    title: "Average Meeting Duration",
                    value: "\(analyticsService.averageMeetingDuration) minutes",
                    description: "Based on all recorded meetings"
                )

                // Most Used Platform
                if let platform = analyticsService.mostUsedPlatform {
                    InsightCard(
                        icon: "video.fill",
                        title: "Most Used Platform",
                        value: platform,
                        description: "Your go-to meeting tool"
                    )
                }

                // Meetings by Day
                VStack(alignment: .leading, spacing: 12) {
                    Text("Meetings by Day of Week")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack(spacing: 8) {
                        ForEach(1...7, id: \.self) { day in
                            let count = analyticsService.meetingsByDayOfWeek[day] ?? 0
                            DayColumn(day: day, count: count, maxCount: maxMeetingsInDay)
                        }
                    }
                    .frame(height: 100)
                }
                .padding()
                .background(Color.primary.opacity(0.03))
                .cornerRadius(12)

                // Data Management
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Management")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(analyticsService.meetingRecords.count) meetings recorded")
                            Text("Data stored locally on your Mac")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Clear Data") {
                            analyticsService.clearAllData()
                        }
                        .foregroundStyle(.red)
                    }
                }
                .padding()
                .background(Color.primary.opacity(0.03))
                .cornerRadius(12)
            }
            .padding()
        }
    }

    private var maxMeetingsInDay: Int {
        analyticsService.meetingsByDayOfWeek.values.max() ?? 1
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Meeting Data Yet")
                .font(.headline)

            Text("Meeting analytics will appear here as your calendar events are recorded.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.primary.opacity(0.03))
        .cornerRadius(12)
    }
}

// MARK: - Daily Stat Row
struct DailyStatRow: View {
    let stat: DailyMeetingStats

    var body: some View {
        HStack {
            Text(stat.formattedDate)
                .font(.caption)
                .frame(width: 80, alignment: .leading)

            // Visual bar
            GeometryReader { geometry in
                let maxMinutes = 480.0 // 8 hours
                let width = min(CGFloat(stat.totalMinutes) / maxMinutes, 1.0) * geometry.size.width
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.opacity(0.6))
                    .frame(width: width)
            }
            .frame(height: 20)

            Text("\(stat.totalMeetings)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 30, alignment: .trailing)

            Text(stat.formattedDuration)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 50, alignment: .trailing)
        }
    }
}

// MARK: - Free Block Row
struct FreeBlockRow: View {
    let block: MeetingFreeBlock

    var body: some View {
        HStack {
            Image(systemName: "clock.badge.checkmark")
                .foregroundStyle(.green)

            VStack(alignment: .leading) {
                Text(block.timeRange)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(block.duration)h free")
                .font(.caption)
                .foregroundStyle(.green)
        }
        .padding(.vertical, 4)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: block.date)
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let icon: String
    let title: String
    let value: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.headline)

                Text(description)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding()
        .background(Color.primary.opacity(0.03))
        .cornerRadius(12)
    }
}

// MARK: - Day Column
struct DayColumn: View {
    let day: Int
    let count: Int
    let maxCount: Int

    private let dayNames = ["", "S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: 4) {
            Spacer()

            RoundedRectangle(cornerRadius: 4)
                .fill(count > 0 ? Color.blue : Color.secondary.opacity(0.2))
                .frame(height: maxCount > 0 ? CGFloat(count) / CGFloat(maxCount) * 60 + 10 : 10)

            Text(dayNames[day])
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    MeetingAnalyticsView()
        .frame(width: 400, height: 500)
}
