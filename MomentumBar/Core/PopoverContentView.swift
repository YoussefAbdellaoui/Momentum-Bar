//
//  PopoverContentView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI
import Combine
import AppKit

struct PopoverContentView: View {
    @State private var selectedTab = 0
    private let defaultPopoverSize = NSSize(width: 420, height: 520)
    private let settingsPopoverSize = NSSize(width: 900, height: 620)

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
        case 6: return "Announcements"
        case 7: return "Settings"
        default: return ""
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView()

            Divider()

            // Tab selector (hide when in Settings to avoid confusion)
            if selectedTab != 7 {
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
            }

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
                case 6:
                    AnnouncementListView(onClose: { selectedTab = 0 })
                case 7:
                    SettingsPanelView(onClose: { selectedTab = 0 })
                default:
                    EmptyView()
                }
            }
            .frame(maxHeight: .infinity)

            Divider()

            // Footer with settings
            FooterView(selectedTab: $selectedTab)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            if OnboardingService.shared.hasCompletedOnboarding {
                _ = await AnnouncementService.shared.refreshAnnouncements()
            }
        }
        .onAppear {
            requestPopoverResize(for: selectedTab)
        }
        .onChange(of: selectedTab) { _, newValue in
            requestPopoverResize(for: newValue)
        }
    }

    private func requestPopoverResize(for tab: Int) {
        let size = (tab == 7) ? settingsPopoverSize : defaultPopoverSize
        NotificationCenter.default.post(
            name: .popoverResizeRequested,
            object: NSValue(size: size)
        )
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
    @Binding var selectedTab: Int
    @State private var isPinned: Bool = false
    @State private var announcementService = AnnouncementService.shared

    var body: some View {
        HStack {
            Button {
                selectedTab = 6
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.body)

                    if announcementService.unreadCount > 0 {
                        ZStack {
                            Circle()
                                .fill(Color.red)
                            Text("\(min(announcementService.unreadCount, 9))")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 14, height: 14)
                        .offset(x: 6, y: -6)
                    }
                }
            }
            .buttonStyle(.plain)
            .help("Announcements")

            Button {
                selectedTab = 7
            } label: {
                Image(systemName: "gearshape")
                    .font(.body)
            }
            .buttonStyle(.plain)
            .help("Settings")

            Spacer()

            // Pin button
            Button {
                MenuBarController.shared?.togglePin()
            } label: {
                Image(systemName: isPinned ? "pin.fill" : "pin")
                    .font(.body)
                    .foregroundStyle(isPinned ? Color.accentColor : .primary)
            }
            .buttonStyle(.plain)
            .help(isPinned ? "Unpin from screen" : "Pin to screen")

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
        .onAppear {
            isPinned = MenuBarController.shared?.isPinned ?? false
        }
        .onReceive(NotificationCenter.default.publisher(for: .popoverPinStateChanged)) { _ in
            isPinned = MenuBarController.shared?.isPinned ?? false
        }
    }
}

#Preview {
    PopoverContentView()
}
