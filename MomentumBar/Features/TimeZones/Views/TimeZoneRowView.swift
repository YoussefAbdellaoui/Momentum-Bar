//
//  TimeZoneRowView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI

struct TimeZoneRowView: View {
    let entry: TimeZoneEntry
    @State private var appState = AppState.shared

    var body: some View {
        HStack(spacing: 12) {
            // Day/Night indicator
            if appState.preferences.showDayNightIndicator {
                DayNightIndicator(isDaytime: isDaytime)
            }

            // Time zone info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(entry.displayName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    // Pin indicator for pinned timezones
                    if entry.isPinnedToMenuBar {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }

                    if let group = groupForEntry {
                        Text(group.name)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(group.color.opacity(0.2))
                            .foregroundStyle(group.color)
                            .cornerRadius(4)
                    }
                }

                HStack(spacing: 4) {
                    Text(entry.abbreviation)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text(entry.currentOffset)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Current time
            VStack(alignment: appState.preferences.timeAlignment.alignment, spacing: 2) {
                Text(formattedTime)
                    .font(timeFont)
                    .fontWeight(appState.preferences.fontWeight.weight)

                if showDate {
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isDaytime ? Color.clear : Color.primary.opacity(0.03))
        )
    }

    private var isDaytime: Bool {
        guard let tz = entry.timeZone else { return true }
        return appState.isDaytime(for: tz)
    }

    private var groupForEntry: TimezoneGroup? {
        guard let groupID = entry.groupID else { return nil }
        return appState.groups.first { $0.id == groupID }
    }

    private var formattedTime: String {
        guard let tz = entry.timeZone else { return "--:--" }
        return appState.formattedTime(for: tz)
    }

    private var formattedDate: String {
        guard let tz = entry.timeZone else { return "" }
        return appState.formattedDate(for: tz)
    }

    private var showDate: Bool {
        // Show date if it differs from local date
        guard let tz = entry.timeZone else { return false }
        let localDate = appState.formattedDate(for: TimeZone.current)
        let zoneDate = appState.formattedDate(for: tz)
        return localDate != zoneDate
    }

    private var timeFont: Font {
        let fontFamily = appState.preferences.fontFamily
        if let fontName = fontFamily.fontName {
            return .custom(fontName, size: 17)
        } else {
            return .system(.title3, design: .monospaced)
        }
    }
}

// MARK: - Day/Night Indicator
struct DayNightIndicator: View {
    let isDaytime: Bool
    @State private var themeManager = ThemeManager.shared

    var body: some View {
        ZStack {
            Circle()
                .fill(indicatorColor.opacity(0.2))
                .frame(width: 28, height: 28)

            Image(systemName: isDaytime ? "sun.max.fill" : "moon.fill")
                .font(.system(size: 14))
                .foregroundStyle(indicatorColor)
        }
    }

    private var indicatorColor: Color {
        isDaytime ? themeManager.currentTheme.daytimeColor : themeManager.currentTheme.nighttimeColor
    }
}

#Preview {
    VStack {
        TimeZoneRowView(entry: TimeZoneEntry(
            identifier: "America/New_York",
            customName: "New York Office"
        ))

        TimeZoneRowView(entry: TimeZoneEntry(
            identifier: "Asia/Tokyo",
            customName: nil
        ))

        TimeZoneRowView(entry: TimeZoneEntry(
            identifier: "Europe/London"
        ))
    }
    .padding()
    .frame(width: 380)
}
