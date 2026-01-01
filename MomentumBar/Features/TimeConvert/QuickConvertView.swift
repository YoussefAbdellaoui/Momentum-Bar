//
//  QuickConvertView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI

struct QuickConvertView: View {
    @State private var appState = AppState.shared
    @State private var inputTime = Date()
    @State private var sourceZone: TimeZone = .current
    @State private var showResults = true

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text("Time Converter")
                    .font(.headline)
                Spacer()
            }

            Divider()

            // Input Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Convert from")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    // Source timezone picker
                    Picker("", selection: $sourceZone) {
                        Text("Local (\(TimeZone.current.abbreviation() ?? ""))").tag(TimeZone.current)
                        ForEach(appState.timeZones, id: \.id) { entry in
                            if let tz = entry.timeZone {
                                Text(entry.displayName).tag(tz)
                            }
                        }
                    }
                    .frame(width: 150)

                    DatePicker("", selection: $inputTime, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(.field)
                        .frame(width: 100)

                    Button {
                        inputTime = Date()
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                    .buttonStyle(.plain)
                    .help("Reset to now")
                }
            }

            Divider()

            // Results
            if showResults {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Converted times")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ScrollView {
                        LazyVStack(spacing: 6) {
                            // Always show local time if not source
                            if sourceZone != TimeZone.current {
                                ConvertedTimeRow(
                                    label: "Local",
                                    abbreviation: TimeZone.current.abbreviation() ?? "LT",
                                    time: convertedTime(to: TimeZone.current),
                                    date: convertedDate(to: TimeZone.current),
                                    isSource: false
                                )
                            }

                            // Show all saved timezones
                            ForEach(appState.timeZones) { entry in
                                if let tz = entry.timeZone, tz != sourceZone {
                                    ConvertedTimeRow(
                                        label: entry.displayName,
                                        abbreviation: entry.abbreviation,
                                        time: convertedTime(to: tz),
                                        date: convertedDate(to: tz),
                                        isSource: false
                                    )
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }

            // Quick presets
            HStack {
                Text("Quick:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("9 AM") { setTime(hour: 9, minute: 0) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Button("12 PM") { setTime(hour: 12, minute: 0) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Button("3 PM") { setTime(hour: 15, minute: 0) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Button("6 PM") { setTime(hour: 18, minute: 0) }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                Spacer()
            }
        }
        .padding()
        .frame(width: 350)
    }

    private func convertedTime(to zone: TimeZone) -> String {
        // Convert inputTime from source timezone to target timezone
        let formatter = DateFormatter()
        formatter.timeZone = zone

        if appState.preferences.use24HourFormat {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "h:mm a"
        }

        // Calculate the offset difference and adjust
        let sourceOffset = sourceZone.secondsFromGMT(for: inputTime)
        let targetOffset = zone.secondsFromGMT(for: inputTime)
        let difference = targetOffset - sourceOffset

        let adjustedTime = inputTime.addingTimeInterval(TimeInterval(difference))
        return formatter.string(from: adjustedTime)
    }

    private func convertedDate(to zone: TimeZone) -> String? {
        let sourceOffset = sourceZone.secondsFromGMT(for: inputTime)
        let targetOffset = zone.secondsFromGMT(for: inputTime)
        let difference = targetOffset - sourceOffset
        let adjustedTime = inputTime.addingTimeInterval(TimeInterval(difference))

        let calendar = Calendar.current
        let sourceDay = calendar.dateComponents(in: sourceZone, from: inputTime).day
        let targetDay = calendar.dateComponents(in: zone, from: adjustedTime).day

        if sourceDay != targetDay {
            let formatter = DateFormatter()
            formatter.timeZone = zone
            formatter.dateFormat = "MMM d"
            return formatter.string(from: adjustedTime)
        }

        return nil
    }

    private func setTime(hour: Int, minute: Int) {
        var components = Calendar.current.dateComponents(in: sourceZone, from: Date())
        components.hour = hour
        components.minute = minute
        components.second = 0

        if let newTime = Calendar.current.date(from: components) {
            inputTime = newTime
        }
    }
}

// MARK: - Converted Time Row
struct ConvertedTimeRow: View {
    let label: String
    let abbreviation: String
    let time: String
    let date: String?
    let isSource: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(abbreviation)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(time)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.medium)

                if let date = date {
                    Text(date)
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.primary.opacity(0.03))
        )
    }
}

#Preview {
    QuickConvertView()
}
