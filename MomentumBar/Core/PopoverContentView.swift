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

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView()

            Divider()

            // Tab selector
            Picker("", selection: $selectedTab) {
                Text("Time Zones").tag(0)
                Text("Calendar").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Content based on selected tab
            TabView(selection: $selectedTab) {
                VStack(spacing: 0) {
                    TimeZonesTabView()

                    Divider()
                        .padding(.top, 8)

                    TimeScrollerView()
                        .padding(.vertical, 8)
                }
                .tag(0)

                CalendarTabView()
                    .tag(1)
            }
            .tabViewStyle(.automatic)

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
