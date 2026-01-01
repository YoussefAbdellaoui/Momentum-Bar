//
//  WorldClockView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI

struct WorldClockView: View {
    @State private var appState = AppState.shared

    var body: some View {
        VStack(spacing: 12) {
            // Visual timeline showing 24 hours
            TimelineVisualization()

            // Timezone bars
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(appState.timeZones) { entry in
                        TimeZoneBar(entry: entry)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }
}

// MARK: - Timeline Visualization
struct TimelineVisualization: View {
    @State private var appState = AppState.shared
    @State private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 4) {
            // Hour markers
            HStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                    Text(hour % 6 == 0 ? "\(hour)" : "")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)

            // Day/Night gradient bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background gradient showing day/night
                    LinearGradient(
                        colors: dayNightColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .cornerRadius(4)

                    // Current time indicator
                    Rectangle()
                        .fill(Color.red)
                        .frame(width: 2)
                        .offset(x: currentTimeOffset(in: geometry.size.width))
                }
            }
            .frame(height: 20)
            .padding(.horizontal, 8)

            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(themeManager.currentTheme.daytimeColor.opacity(0.6))
                        .frame(width: 8, height: 8)
                    Text("Day")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Circle()
                        .fill(themeManager.currentTheme.nighttimeColor.opacity(0.6))
                        .frame(width: 8, height: 8)
                    Text("Night")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("UTC: \(utcTime)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
        }
    }

    private var dayNightColors: [Color] {
        // Create gradient representing day/night across 24 hours
        var colors: [Color] = []
        for hour in 0..<24 {
            if hour >= 6 && hour < 18 {
                colors.append(themeManager.currentTheme.daytimeColor.opacity(0.4))
            } else {
                colors.append(themeManager.currentTheme.nighttimeColor.opacity(0.4))
            }
        }
        return colors
    }

    private func currentTimeOffset(in width: CGFloat) -> CGFloat {
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: appState.currentTime)
        let hour = Double(components.hour ?? 0)
        let minute = Double(components.minute ?? 0)
        let percentage = (hour + minute / 60) / 24.0
        return width * percentage
    }

    private var utcTime: String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: appState.currentTime)
    }
}

// MARK: - Timezone Bar
struct TimeZoneBar: View {
    let entry: TimeZoneEntry
    @State private var appState = AppState.shared
    @State private var themeManager = ThemeManager.shared

    var body: some View {
        HStack(spacing: 8) {
            // Timezone label
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(entry.abbreviation)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80, alignment: .leading)

            // Visual bar showing local time position
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background with day/night
                    HStack(spacing: 0) {
                        ForEach(0..<24, id: \.self) { hour in
                            Rectangle()
                                .fill(isHourDaytime(hour) ? themeManager.currentTheme.daytimeColor.opacity(0.3) : themeManager.currentTheme.nighttimeColor.opacity(0.3))
                        }
                    }
                    .cornerRadius(4)

                    // Current time marker
                    Circle()
                        .fill(isDaytime ? themeManager.currentTheme.daytimeColor : themeManager.currentTheme.nighttimeColor)
                        .frame(width: 10, height: 10)
                        .offset(x: timeOffset(in: geometry.size.width) - 5)
                }
            }
            .frame(height: 16)

            // Current time
            Text(formattedTime)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.03))
        )
    }

    private var isDaytime: Bool {
        guard let tz = entry.timeZone else { return true }
        return appState.isDaytime(for: tz)
    }

    private func isHourDaytime(_ hour: Int) -> Bool {
        return hour >= 6 && hour < 18
    }

    private func timeOffset(in width: CGFloat) -> CGFloat {
        guard let tz = entry.timeZone else { return 0 }
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: tz, from: appState.currentTime)
        let hour = Double(components.hour ?? 0)
        let minute = Double(components.minute ?? 0)
        let percentage = (hour + minute / 60) / 24.0
        return width * percentage
    }

    private var formattedTime: String {
        guard let tz = entry.timeZone else { return "--:--" }
        return appState.formattedTime(for: tz)
    }
}

#Preview {
    WorldClockView()
        .frame(width: 400, height: 300)
}
