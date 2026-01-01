//
//  TimeScrollerView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI

struct TimeScrollerView: View {
    @State private var appState = AppState.shared
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 12) {
            // Toggle button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .foregroundStyle(.blue)

                    Text("Time Travel")
                        .font(.caption)
                        .fontWeight(.medium)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            if isExpanded {
                scrollerContent
            }
        }
        .padding(.horizontal)
    }

    private var scrollerContent: some View {
        VStack(spacing: 16) {
            // Slider
            VStack(spacing: 4) {
                HStack {
                    Text("-24h")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Slider(value: $appState.previewOffsetHours, in: -24...24, step: 0.5)
                        .tint(.blue)

                    Text("+24h")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if appState.isPreviewActive {
                    HStack {
                        Text(offsetLabel)
                            .font(.caption)
                            .foregroundStyle(.blue)

                        Spacer()

                        Button("Reset") {
                            withAnimation {
                                appState.resetPreview()
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            // Preview times
            if appState.isPreviewActive {
                Divider()

                VStack(spacing: 8) {
                    HStack {
                        Text("Preview: \(formattedPreviewTime)")
                            .font(.caption)
                            .fontWeight(.medium)

                        Spacer()
                    }

                    ForEach(appState.timeZones) { entry in
                        TimeZonePreviewRow(entry: entry, previewTime: appState.previewTime)
                    }
                }
            }

            // Optimal meeting times
            if appState.timeZones.count > 1 {
                Divider()
                OptimalMeetingTimeView()
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(8)
    }

    private var offsetLabel: String {
        let hours = abs(Int(appState.previewOffsetHours))
        let direction = appState.previewOffsetHours > 0 ? "ahead" : "behind"
        return "\(hours) hour\(hours == 1 ? "" : "s") \(direction)"
    }

    private var formattedPreviewTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: appState.previewTime)
    }
}

// MARK: - Time Zone Preview Row
struct TimeZonePreviewRow: View {
    let entry: TimeZoneEntry
    let previewTime: Date
    @State private var appState = AppState.shared

    var body: some View {
        HStack {
            // Day/Night indicator for preview time
            DayNightIndicator(isDaytime: isDaytime)
                .scaleEffect(0.8)

            Text(entry.displayName)
                .font(.caption)
                .lineLimit(1)

            Spacer()

            Text(formattedTime)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }

    private var isDaytime: Bool {
        guard let tz = entry.timeZone else { return true }
        return appState.isDaytime(for: tz, at: previewTime)
    }

    private var formattedTime: String {
        guard let tz = entry.timeZone else { return "--:--" }
        return appState.formattedTime(for: tz, time: previewTime)
    }
}

// MARK: - Optimal Meeting Time View
struct OptimalMeetingTimeView: View {
    @State private var appState = AppState.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.yellow)

                Text("Best Meeting Times")
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()
            }

            if optimalSlots.isEmpty {
                Text("No overlapping work hours found")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(optimalSlots.prefix(3), id: \.startHour) { slot in
                    HStack {
                        Text("\(slot.formattedRange)")
                            .font(.caption)

                        Spacer()

                        Text("\(slot.awakeCount)/\(appState.timeZones.count) awake")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var optimalSlots: [MeetingSlot] {
        // Find time windows where most people are awake (9 AM - 6 PM local)
        var slots: [MeetingSlot] = []
        let today = Calendar.current.startOfDay(for: Date())

        for hour in 0..<24 {
            guard let slotTime = Calendar.current.date(byAdding: .hour, value: hour, to: today) else { continue }

            let awakeCount = appState.timeZones.filter { entry in
                guard let tz = entry.timeZone else { return false }
                let components = Calendar.current.dateComponents(in: tz, from: slotTime)
                let localHour = components.hour ?? 12
                // Consider awake if between 9 AM and 6 PM
                return localHour >= 9 && localHour < 18
            }.count

            if awakeCount == appState.timeZones.count {
                slots.append(MeetingSlot(startHour: hour, awakeCount: awakeCount))
            }
        }

        // Merge consecutive slots
        return mergeConsecutiveSlots(slots)
    }

    private func mergeConsecutiveSlots(_ slots: [MeetingSlot]) -> [MeetingSlot] {
        guard !slots.isEmpty else { return [] }

        var merged: [MeetingSlot] = []
        var currentStart = slots[0].startHour
        var currentEnd = slots[0].startHour
        var currentAwake = slots[0].awakeCount

        for i in 1..<slots.count {
            if slots[i].startHour == currentEnd + 1 {
                currentEnd = slots[i].startHour
            } else {
                merged.append(MeetingSlot(startHour: currentStart, endHour: currentEnd + 1, awakeCount: currentAwake))
                currentStart = slots[i].startHour
                currentEnd = slots[i].startHour
                currentAwake = slots[i].awakeCount
            }
        }
        merged.append(MeetingSlot(startHour: currentStart, endHour: currentEnd + 1, awakeCount: currentAwake))

        return merged
    }
}

struct MeetingSlot {
    let startHour: Int
    var endHour: Int?
    let awakeCount: Int

    init(startHour: Int, endHour: Int? = nil, awakeCount: Int) {
        self.startHour = startHour
        self.endHour = endHour
        self.awakeCount = awakeCount
    }

    var formattedRange: String {
        let start = formatHour(startHour)
        let end = formatHour(endHour ?? (startHour + 1))
        return "\(start) - \(end) (your time)"
    }

    private func formatHour(_ hour: Int) -> String {
        let h = hour % 24
        if h == 0 { return "12 AM" }
        if h == 12 { return "12 PM" }
        if h < 12 { return "\(h) AM" }
        return "\(h - 12) PM"
    }
}

#Preview {
    TimeScrollerView()
        .frame(width: 400)
        .padding()
}
