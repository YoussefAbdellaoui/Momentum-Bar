//
//  SettingsView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI
import ServiceManagement

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general
        case timeZones
        case calendar
        case display
        case about
    }

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(Tabs.general)

            TimeZoneSettingsTab()
                .tabItem {
                    Label("Time Zones", systemImage: "globe")
                }
                .tag(Tabs.timeZones)

            CalendarSettingsTab()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(Tabs.calendar)

            DisplaySettingsTab()
                .tabItem {
                    Label("Display", systemImage: "paintbrush")
                }
                .tag(Tabs.display)

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(Tabs.about)
        }
        .frame(width: 500, height: 380)
    }
}

// MARK: - General Settings Tab
struct GeneralSettingsTab: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("menuBarDisplayMode") private var menuBarDisplayMode = "icon"

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch MomentumBar at login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            }

            Section("Menu Bar") {
                Picker("Display mode", selection: $menuBarDisplayMode) {
                    Text("Icon only").tag("icon")
                    Text("Time only").tag("time")
                    Text("Icon and time").tag("both")
                }
                .pickerStyle(.radioGroup)
            }

            Section("Keyboard Shortcuts") {
                Text("Coming soon...")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
        }
    }
}

// MARK: - Time Zone Settings Tab
struct TimeZoneSettingsTab: View {
    var body: some View {
        Form {
            Section("Saved Time Zones") {
                Text("Manage your time zones from the main popover")
                    .foregroundStyle(.secondary)
            }

            Section("Default Time Zone") {
                Text("System: \(TimeZone.current.identifier)")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Calendar Settings Tab
struct CalendarSettingsTab: View {
    var body: some View {
        Form {
            Section("Calendar Access") {
                Text("Grant calendar access to see upcoming events")
                    .foregroundStyle(.secondary)

                Button("Open System Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }

            Section("Meeting Reminders") {
                Text("Coming soon...")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Display Settings Tab
struct DisplaySettingsTab: View {
    @AppStorage("use24HourFormat") private var use24HourFormat = false
    @AppStorage("showSeconds") private var showSeconds = false
    @AppStorage("showDayNightIndicator") private var showDayNightIndicator = true

    var body: some View {
        Form {
            Section("Time Format") {
                Picker("Format", selection: $use24HourFormat) {
                    Text("12-hour (3:45 PM)").tag(false)
                    Text("24-hour (15:45)").tag(true)
                }
                .pickerStyle(.radioGroup)

                Toggle("Show seconds", isOn: $showSeconds)
            }

            Section("Appearance") {
                Toggle("Show day/night indicators", isOn: $showDayNightIndicator)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About Tab
struct AboutTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("MomentumBar")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("A beautiful time zone and calendar manager for your menu bar")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            Text("Made with love")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
}
