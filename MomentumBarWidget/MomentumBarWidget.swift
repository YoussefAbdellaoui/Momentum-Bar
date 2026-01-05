//
//  MomentumBarWidget.swift
//  MomentumBarWidget
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct TimeZoneWidgetEntry: TimelineEntry {
    let date: Date
    let timeZones: [WidgetTimeZone]
    let configuration: ConfigurationAppIntent
}

struct WidgetTimeZone: Identifiable {
    let id: String
    let displayName: String
    let abbreviation: String
    let currentTime: String
    let isDaytime: Bool
    let offset: String
}

// MARK: - Timeline Provider
struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TimeZoneWidgetEntry {
        TimeZoneWidgetEntry(
            date: Date(),
            timeZones: sampleTimeZones(),
            configuration: ConfigurationAppIntent()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> TimeZoneWidgetEntry {
        TimeZoneWidgetEntry(
            date: Date(),
            timeZones: loadTimeZones(),
            configuration: configuration
        )
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<TimeZoneWidgetEntry> {
        var entries: [TimeZoneWidgetEntry] = []
        let currentDate = Date()

        // Generate entries for the next hour, one per minute
        for minuteOffset in 0..<60 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = TimeZoneWidgetEntry(
                date: entryDate,
                timeZones: loadTimeZones(at: entryDate),
                configuration: configuration
            )
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    // MARK: - Data Loading
    private func loadTimeZones(at date: Date = Date()) -> [WidgetTimeZone] {
        // Load from shared UserDefaults (App Group)
        let defaults = UserDefaults(suiteName: AppGroup.suiteName)

        guard let data = defaults?.data(forKey: AppGroup.timeZonesKey),
              let entries = try? JSONDecoder().decode([SharedTimeZoneEntry].self, from: data) else {
            return sampleTimeZones()
        }

        // Load preferences
        let use24Hour = defaults?.bool(forKey: AppGroup.use24HourKey) ?? false

        return entries.prefix(4).map { entry in
            let tz = TimeZone(identifier: entry.identifier) ?? .current
            return WidgetTimeZone(
                id: entry.id,
                displayName: entry.customName ?? cityName(from: entry.identifier),
                abbreviation: tz.abbreviation() ?? "UTC",
                currentTime: formatTime(date, timeZone: tz, use24Hour: use24Hour),
                isDaytime: isDaytime(date, timeZone: tz),
                offset: formatOffset(tz)
            )
        }
    }

    private func sampleTimeZones() -> [WidgetTimeZone] {
        [
            WidgetTimeZone(id: "1", displayName: "New York", abbreviation: "EST", currentTime: "3:45 PM", isDaytime: true, offset: "UTC-5"),
            WidgetTimeZone(id: "2", displayName: "London", abbreviation: "GMT", currentTime: "8:45 PM", isDaytime: false, offset: "UTC+0"),
            WidgetTimeZone(id: "3", displayName: "Tokyo", abbreviation: "JST", currentTime: "5:45 AM", isDaytime: false, offset: "UTC+9")
        ]
    }

    private func cityName(from identifier: String) -> String {
        let parts = identifier.split(separator: "/")
        let city = parts.last ?? Substring(identifier)
        return String(city).replacingOccurrences(of: "_", with: " ")
    }

    private func formatTime(_ date: Date, timeZone: TimeZone, use24Hour: Bool) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = use24Hour ? "HH:mm" : "h:mm a"
        return formatter.string(from: date)
    }

    private func isDaytime(_ date: Date, timeZone: TimeZone) -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: date)
        return hour >= 6 && hour < 18
    }

    private func formatOffset(_ timeZone: TimeZone) -> String {
        let seconds = timeZone.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = abs(seconds / 60) % 60

        if minutes == 0 {
            return "UTC\(hours >= 0 ? "+" : "")\(hours)"
        } else {
            return String(format: "UTC%@%d:%02d", hours >= 0 ? "+" : "", hours, minutes)
        }
    }
}

// MARK: - Shared Model (must match WidgetTimeZoneEntry in main app)
struct SharedTimeZoneEntry: Codable {
    let id: String
    let identifier: String
    let customName: String?
    let order: Int
}

// MARK: - App Group Constants
private enum AppGroup {
    static let suiteName = "group.com.momentumbar.shared"
    static let timeZonesKey = "com.momentumbar.timezones"
    static let use24HourKey = "com.momentumbar.use24HourFormat"
}

// MARK: - Configuration Intent
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuration"
    static var description = IntentDescription("Configure your timezone widget.")

    @Parameter(title: "Show Offset", default: true)
    var showOffset: Bool

    @Parameter(title: "Compact Mode", default: false)
    var compactMode: Bool
}

// MARK: - Widget Views
struct MomentumBarWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: TimeZoneWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with local time
            HStack {
                Image(systemName: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(localTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Show first 2 timezones
            ForEach(entry.timeZones.prefix(2)) { tz in
                HStack {
                    Circle()
                        .fill(tz.isDaytime ? Color.yellow : Color.indigo)
                        .frame(width: 8, height: 8)

                    Text(tz.displayName)
                        .font(.caption)
                        .lineLimit(1)

                    Spacer()

                    Text(tz.currentTime)
                        .font(.system(.caption, design: .monospaced))
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
    }

    private var localTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: entry.date)
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: TimeZoneWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            // Local time section
            VStack(alignment: .leading, spacing: 4) {
                Text("Local")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(localTime)
                    .font(.system(.title, design: .monospaced))
                    .fontWeight(.semibold)

                Text(localDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 90)

            Divider()

            // Timezones grid
            VStack(alignment: .leading, spacing: 6) {
                ForEach(entry.timeZones.prefix(4)) { tz in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(tz.isDaytime ? Color.yellow : Color.indigo)
                            .frame(width: 8, height: 8)

                        Text(tz.displayName)
                            .font(.caption)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if entry.configuration.showOffset {
                            Text(tz.abbreviation)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        Text(tz.currentTime)
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
    }

    private var localTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: entry.date)
    }

    private var localDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: entry.date)
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: TimeZoneWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("World Clock")
                        .font(.headline)

                    Text(localDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(localTime)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.semibold)
            }

            Divider()

            // Timezone list
            ForEach(entry.timeZones) { tz in
                HStack(spacing: 12) {
                    // Day/Night indicator
                    ZStack {
                        Circle()
                            .fill(tz.isDaytime ? Color.yellow.opacity(0.2) : Color.indigo.opacity(0.2))
                            .frame(width: 32, height: 32)

                        Image(systemName: tz.isDaytime ? "sun.max.fill" : "moon.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(tz.isDaytime ? .yellow : .indigo)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(tz.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        HStack(spacing: 4) {
                            Text(tz.abbreviation)
                            Text("•")
                            Text(tz.offset)
                        }
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(tz.currentTime)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.medium)
                }
                .padding(.vertical, 4)
            }

            Spacer()
        }
        .padding()
    }

    private var localTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: entry.date)
    }

    private var localDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: entry.date)
    }
}

// MARK: - World Clock Widget Definition
struct WorldClockWidget: Widget {
    let kind: String = "MomentumBarWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            MomentumBarWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("World Clock")
        .description("View your favorite time zones at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Bundle (combines all widgets)
@main
struct MomentumBarWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorldClockWidget()
        PomodoroWidget()
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    WorldClockWidget()
} timeline: {
    TimeZoneWidgetEntry(
        date: .now,
        timeZones: [
            WidgetTimeZone(id: "1", displayName: "New York", abbreviation: "EST", currentTime: "3:45 PM", isDaytime: true, offset: "UTC-5"),
            WidgetTimeZone(id: "2", displayName: "London", abbreviation: "GMT", currentTime: "8:45 PM", isDaytime: false, offset: "UTC+0")
        ],
        configuration: ConfigurationAppIntent()
    )
}

#Preview(as: .systemMedium) {
    WorldClockWidget()
} timeline: {
    TimeZoneWidgetEntry(
        date: .now,
        timeZones: [
            WidgetTimeZone(id: "1", displayName: "New York", abbreviation: "EST", currentTime: "3:45 PM", isDaytime: true, offset: "UTC-5"),
            WidgetTimeZone(id: "2", displayName: "London", abbreviation: "GMT", currentTime: "8:45 PM", isDaytime: false, offset: "UTC+0"),
            WidgetTimeZone(id: "3", displayName: "Tokyo", abbreviation: "JST", currentTime: "5:45 AM", isDaytime: false, offset: "UTC+9"),
            WidgetTimeZone(id: "4", displayName: "Sydney", abbreviation: "AEDT", currentTime: "7:45 AM", isDaytime: true, offset: "UTC+11")
        ],
        configuration: ConfigurationAppIntent()
    )
}
