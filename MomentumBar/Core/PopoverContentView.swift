//
//  PopoverContentView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI
import Combine

struct PopoverContentView: View {
    @State private var selectedTab = 0

    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "clock"
        case 1: return "globe"
        case 2: return "arrow.left.arrow.right"
        case 3: return "calendar"
        case 4: return "timer"
        case 5: return "chart.bar"
        default: return "circle"
        }
    }

    private func tabLabel(for index: Int) -> String {
        switch index {
        case 0: return "Time Zones"
        case 1: return "World Clock"
        case 2: return "Convert"
        case 3: return "Calendar"
        case 4: return "Pomodoro"
        case 5: return "Analytics"
        default: return ""
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView()

            Divider()

            // Tab selector
            HStack(spacing: 4) {
                ForEach(0..<6, id: \.self) { index in
                    Button {
                        selectedTab = index
                    } label: {
                        Image(systemName: tabIcon(for: index))
                            .font(.system(size: 14))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedTab == index ? Color.accentColor.opacity(0.15) : Color.clear)
                            )
                            .foregroundStyle(selectedTab == index ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(tabLabel(for: index))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Content based on selected tab
            Group {
                switch selectedTab {
                case 0:
                    VStack(spacing: 0) {
                        TimeZonesTabView()

                        Divider()
                            .padding(.top, 8)

                        TimeScrollerView()
                            .padding(.vertical, 8)
                    }
                case 1:
                    WorldClockView()
                case 2:
                    QuickConvertView()
                case 3:
                    CalendarTabView()
                case 4:
                    PomodoroView()
                case 5:
                    MeetingAnalyticsView()
                default:
                    EmptyView()
                }
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Footer with settings
            FooterView()
        }
        .frame(width: 420, height: 520)
    }
}

// MARK: - Header View
struct HeaderView: View {
    @State private var appState = AppState.shared

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("MomentumBar")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedTime)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.medium)

                if appState.timeZones.count > 1 {
                    Text("\(appState.awakeCount) awake, \(appState.asleepCount) asleep")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: appState.currentTime)
    }

    private var formattedTime: String {
        appState.formattedTime(for: TimeZone.current)
    }
}

// MARK: - Time Zones Tab
struct TimeZonesTabView: View {
    var body: some View {
        TimeZoneListView()
    }
}

// MARK: - Calendar Tab
struct CalendarTabView: View {
    var body: some View {
        CalendarView()
    }
}

// MARK: - Footer View
struct FooterView: View {
    var body: some View {
        HStack {
            SettingsLink {
                Image(systemName: "gearshape")
                    .font(.body)
            }
            .buttonStyle(.plain)
            .help("Settings")

            Spacer()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.body)
            }
            .buttonStyle(.plain)
            .help("Quit MomentumBar")
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

#Preview {
    PopoverContentView()
}
