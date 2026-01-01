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
                Text(entry.displayName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .lineLimit(1)

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
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedTime)
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.medium)

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
}

// MARK: - Day/Night Indicator
struct DayNightIndicator: View {
    let isDaytime: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isDaytime ? Color.yellow.opacity(0.2) : Color.indigo.opacity(0.2))
                .frame(width: 28, height: 28)

            Image(systemName: isDaytime ? "sun.max.fill" : "moon.fill")
                .font(.system(size: 14))
                .foregroundStyle(isDaytime ? .yellow : .indigo)
        }
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
