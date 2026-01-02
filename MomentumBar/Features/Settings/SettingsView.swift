//
//  SettingsView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI
import ServiceManagement
import EventKit

struct SettingsView: View {
    private enum Tabs: Hashable {
        case general
        case timeZones
        case calendar
        case focus
        case display
        case theme
        case license
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

            FocusSettingsTab()
                .tabItem {
                    Label("Focus", systemImage: "moon.fill")
                }
                .tag(Tabs.focus)

            DisplaySettingsTab()
                .tabItem {
                    Label("Display", systemImage: "paintbrush")
                }
                .tag(Tabs.display)

            ThemeSettingsTab()
                .tabItem {
                    Label("Theme", systemImage: "paintpalette")
                }
                .tag(Tabs.theme)

            LicenseSettingsView()
                .tabItem {
                    Label("License", systemImage: "key.fill")
                }
                .tag(Tabs.license)

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(Tabs.about)
        }
        .frame(width: 500, height: 500)
    }
}

// MARK: - General Settings Tab
struct GeneralSettingsTab: View {
    @State private var appState = AppState.shared

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch MomentumBar at login", isOn: Binding(
                    get: { appState.preferences.launchAtLogin },
                    set: { newValue in
                        appState.preferences.launchAtLogin = newValue
                        setLaunchAtLogin(newValue)
                    }
                ))

                Toggle("Hide dock icon (menu bar only)", isOn: Binding(
                    get: { appState.preferences.hideDockIcon },
                    set: { appState.preferences.hideDockIcon = $0 }
                ))
            }

            Section("Menu Bar") {
                Picker("Display mode", selection: Binding(
                    get: { appState.preferences.menuBarDisplayMode },
                    set: { appState.preferences.menuBarDisplayMode = $0 }
                )) {
                    Text("Icon only").tag(MenuBarDisplayMode.icon)
                    Text("Time only").tag(MenuBarDisplayMode.time)
                    Text("Icon and time").tag(MenuBarDisplayMode.iconAndTime)
                }
                .pickerStyle(.radioGroup)

                Toggle("Show meeting badge on dock", isOn: Binding(
                    get: { appState.preferences.showMeetingBadge },
                    set: { appState.preferences.showMeetingBadge = $0 }
                ))

                Toggle("Show next meeting countdown", isOn: Binding(
                    get: { appState.preferences.showNextMeetingTime },
                    set: { appState.preferences.showNextMeetingTime = $0 }
                ))
            }

            Section("Keyboard Shortcuts") {
                ShortcutRow(
                    label: "Toggle Popover",
                    shortcut: appState.preferences.togglePopoverShortcut
                )

                ShortcutRow(
                    label: "Add Time Zone",
                    shortcut: appState.preferences.addTimeZoneShortcut
                )

                ShortcutRow(
                    label: "Open Settings",
                    shortcut: appState.preferences.openSettingsShortcut
                )

                Text("Shortcuts take effect after restart")
                    .font(.caption)
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

// MARK: - Shortcut Row
struct ShortcutRow: View {
    let label: String
    let shortcut: KeyboardShortcut

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(shortcut.displayString)
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
        }
    }
}

// MARK: - Time Zone Settings Tab
struct TimeZoneSettingsTab: View {
    @State private var appState = AppState.shared
    @State private var showAddGroup = false
    @State private var newGroupName = ""

    var body: some View {
        Form {
            Section("Groups") {
                ForEach(appState.groups) { group in
                    HStack {
                        Image(systemName: group.icon)
                            .foregroundStyle(group.color)
                        Text(group.name)
                        Spacer()
                        Text("\(appState.timeZones(for: group).count) zones")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            deleteGroup(group)
                        }
                    }
                }

                if showAddGroup {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Enter group name", text: $newGroupName)
                            .textFieldStyle(.roundedBorder)

                        HStack {
                            Button("Add Group") {
                                addGroup()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(newGroupName.trimmingCharacters(in: .whitespaces).isEmpty)

                            Button("Cancel") {
                                showAddGroup = false
                                newGroupName = ""
                            }
                            .controlSize(.small)
                        }
                    }
                } else {
                    Button {
                        showAddGroup = true
                    } label: {
                        Label("Add Group", systemImage: "plus")
                    }
                }
            }

            Section("Saved Time Zones") {
                if appState.timeZones.isEmpty {
                    Text("No time zones saved")
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(appState.timeZones.count) time zones configured")
                        .foregroundStyle(.secondary)
                    Text("Manage from the main popover")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Section("Default Time Zone") {
                Text("System: \(TimeZone.current.identifier)")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func addGroup() {
        let group = TimezoneGroup(
            name: newGroupName,
            order: appState.groups.count
        )
        appState.groups.append(group)
        newGroupName = ""
        showAddGroup = false
    }

    private func deleteGroup(_ group: TimezoneGroup) {
        // Remove group from all timezones
        for i in appState.timeZones.indices {
            if appState.timeZones[i].groupID == group.id {
                appState.timeZones[i].groupID = nil
            }
        }
        appState.groups.removeAll { $0.id == group.id }
    }
}

// MARK: - Calendar Settings Tab
struct CalendarSettingsTab: View {
    @State private var appState = AppState.shared
    @StateObject private var calendarService = CalendarService.shared
    @StateObject private var notificationService = NotificationService.shared
    @State private var selectedCalendarIDs: Set<String> = []

    var body: some View {
        Form {
            Section("Calendar Access") {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(calendarStatusText)
                        .foregroundStyle(calendarStatusColor)
                }

                if calendarService.authorizationStatus != .fullAccess {
                    Button("Grant Calendar Access") {
                        Task {
                            await calendarService.requestAccess()
                        }
                    }

                    Button("Open System Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.link)
                }
            }

            if calendarService.authorizationStatus == .fullAccess {
                Section("Calendars to Monitor") {
                    if calendarService.availableCalendars.isEmpty {
                        Text("No calendars found")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(calendarService.availableCalendars, id: \.calendarIdentifier) { calendar in
                            Toggle(isOn: Binding(
                                get: { selectedCalendarIDs.contains(calendar.calendarIdentifier) },
                                set: { isSelected in
                                    if isSelected {
                                        selectedCalendarIDs.insert(calendar.calendarIdentifier)
                                    } else {
                                        selectedCalendarIDs.remove(calendar.calendarIdentifier)
                                    }
                                    appState.preferences.selectedCalendarIDs = selectedCalendarIDs
                                }
                            )) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(cgColor: calendar.cgColor ?? CGColor(red: 0, green: 0.5, blue: 1, alpha: 1)))
                                        .frame(width: 10, height: 10)
                                    Text(calendar.title)
                                }
                            }
                        }

                        if !selectedCalendarIDs.isEmpty {
                            Text("\(selectedCalendarIDs.count) calendar(s) selected")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Notifications") {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(notificationService.isAuthorized ? "Authorized" : "Not Authorized")
                        .foregroundStyle(notificationService.isAuthorized ? .green : .orange)
                }

                if !notificationService.isAuthorized {
                    Button("Enable Notifications") {
                        Task {
                            await notificationService.requestAuthorization()
                        }
                    }
                }
            }

            Section("Meeting Reminders") {
                Toggle("Show meeting reminders", isOn: Binding(
                    get: { appState.preferences.showMeetingReminders },
                    set: { appState.preferences.showMeetingReminders = $0 }
                ))

                Picker("Remind me", selection: Binding(
                    get: { appState.preferences.meetingReminderMinutes },
                    set: { appState.preferences.meetingReminderMinutes = $0 }
                )) {
                    Text("5 minutes before").tag(5)
                    Text("10 minutes before").tag(10)
                    Text("15 minutes before").tag(15)
                    Text("30 minutes before").tag(30)
                }
                .disabled(!appState.preferences.showMeetingReminders)
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            calendarService.updateAuthorizationStatus()
            notificationService.checkAuthorizationStatus()
            if calendarService.authorizationStatus == .fullAccess {
                calendarService.loadCalendars()
            }
            selectedCalendarIDs = appState.preferences.selectedCalendarIDs
        }
    }

    private var calendarStatusText: String {
        switch calendarService.authorizationStatus {
        case .fullAccess: return "Full Access"
        case .writeOnly: return "Write Only"
        case .denied: return "Denied"
        case .restricted: return "Restricted"
        case .notDetermined: return "Not Determined"
        @unknown default: return "Unknown"
        }
    }

    private var calendarStatusColor: Color {
        switch calendarService.authorizationStatus {
        case .fullAccess: return .green
        case .writeOnly: return .orange
        case .denied, .restricted: return .red
        case .notDetermined: return .secondary
        @unknown default: return .secondary
        }
    }
}

// MARK: - Focus Settings Tab
struct FocusSettingsTab: View {
    @State private var focusService = FocusModeService.shared
    @State private var showSetupSheet = false

    var body: some View {
        Form {
            Section("Focus Mode Status") {
                HStack {
                    Image(systemName: focusService.isFocusModeActive ? "moon.fill" : "moon")
                        .foregroundStyle(focusService.isFocusModeActive ? .purple : .secondary)
                    Text(focusService.isFocusModeActive ? "Focus Mode Active" : "Focus Mode Inactive")
                    Spacer()
                    if focusService.isFocusModeActive, let trigger = focusService.currentTrigger {
                        Text(trigger.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if focusService.isSetupComplete {
                    Button(focusService.isFocusModeActive ? "Disable Focus" : "Enable Focus") {
                        focusService.toggleFocus()
                    }
                }
            }

            Section("Automatic Focus") {
                Toggle("Enable during Pomodoro work sessions", isOn: Binding(
                    get: { focusService.settings.enableDuringPomodoro },
                    set: {
                        focusService.settings.enableDuringPomodoro = $0
                        focusService.saveSettings()
                    }
                ))
                .disabled(!focusService.isSetupComplete)

                if focusService.settings.enableDuringPomodoro {
                    Text("Focus Mode will automatically turn on when you start a Pomodoro work session")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Toggle("Enable during calendar meetings", isOn: Binding(
                    get: { focusService.settings.enableDuringMeetings },
                    set: {
                        focusService.settings.enableDuringMeetings = $0
                        focusService.saveSettings()
                    }
                ))
                .disabled(!focusService.isSetupComplete)

                if focusService.settings.enableDuringMeetings {
                    Text("Focus Mode will automatically turn on during calendar events")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Toggle("Auto-disable after session ends", isOn: Binding(
                    get: { focusService.settings.autoDisableAfterSession },
                    set: {
                        focusService.settings.autoDisableAfterSession = $0
                        focusService.saveSettings()
                    }
                ))
                .disabled(!focusService.isSetupComplete)
            }

            Section("Shortcuts Integration") {
                if focusService.isSetupComplete {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Shortcuts configured")
                        Spacer()
                        Button("Reconfigure") {
                            showSetupSheet = true
                        }
                        .buttonStyle(.link)
                    }

                    TextField("Shortcut Name", text: Binding(
                        get: { focusService.settings.shortcutName },
                        set: {
                            focusService.settings.shortcutName = $0
                            focusService.saveSettings()
                        }
                    ))
                    .textFieldStyle(.roundedBorder)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text("Setup Required")
                                .fontWeight(.medium)
                        }

                        Text("MomentumBar uses macOS Shortcuts to control Focus Mode. You'll need to create a simple shortcut first.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Button("Setup Focus Mode") {
                            showSetupSheet = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .sheet(isPresented: $showSetupSheet) {
            FocusModeSetupSheet(isPresented: $showSetupSheet)
        }
    }
}

// MARK: - Focus Mode Setup Sheet
struct FocusModeSetupSheet: View {
    @Binding var isPresented: Bool
    @State private var focusService = FocusModeService.shared
    @State private var currentStep = 1

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Focus Mode Setup")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.primary.opacity(0.05))

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Progress
                    HStack(spacing: 4) {
                        ForEach(1...6, id: \.self) { step in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(step <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                                .frame(height: 4)
                        }
                    }
                    .padding(.top)

                    // Instructions
                    ForEach(FocusModeService.setupInstructions, id: \.step) { instruction in
                        SetupStepRow(
                            step: instruction.step,
                            title: instruction.title,
                            description: instruction.description,
                            isActive: instruction.step == currentStep,
                            isCompleted: instruction.step < currentStep
                        )
                        .onTapGesture {
                            currentStep = instruction.step
                        }
                    }

                    // Shortcut Template
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shortcut Template")
                            .font(.headline)

                        Text(FocusModeService.shortcutTemplate)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(8)
                    }
                    .padding(.top)
                }
                .padding()
            }

            // Footer
            HStack {
                Button("Open Shortcuts App") {
                    focusService.openShortcutsApp()
                }

                Spacer()

                if currentStep < 6 {
                    Button("Next Step") {
                        currentStep += 1
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Complete Setup") {
                        focusService.completeSetup()
                        isPresented = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(Color.primary.opacity(0.05))
        }
        .frame(width: 500, height: 600)
    }
}

// MARK: - Setup Step Row
struct SetupStepRow: View {
    let step: Int
    let title: String
    let description: String
    let isActive: Bool
    let isCompleted: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : (isActive ? Color.accentColor : Color.secondary.opacity(0.3)))
                    .frame(width: 28, height: 28)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                } else {
                    Text("\(step)")
                        .font(.caption.bold())
                        .foregroundStyle(isActive ? .white : .secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(isActive ? .semibold : .regular)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .opacity(isCompleted ? 0.6 : 1)
    }
}

// MARK: - Display Settings Tab
struct DisplaySettingsTab: View {
    @State private var appState = AppState.shared

    var body: some View {
        Form {
            Section("Time Format") {
                Picker("Format", selection: Binding(
                    get: { appState.preferences.use24HourFormat },
                    set: { appState.preferences.use24HourFormat = $0 }
                )) {
                    Text("12-hour (3:45 PM)").tag(false)
                    Text("24-hour (15:45)").tag(true)
                }
                .pickerStyle(.radioGroup)

                Toggle("Show seconds", isOn: Binding(
                    get: { appState.preferences.showSeconds },
                    set: { appState.preferences.showSeconds = $0 }
                ))

                Picker("Separator", selection: Binding(
                    get: { appState.preferences.timeSeparator },
                    set: { appState.preferences.timeSeparator = $0 }
                )) {
                    ForEach(TimeSeparator.allCases, id: \.self) { separator in
                        Text(separator.description).tag(separator)
                    }
                }
            }

            Section("Font") {
                Picker("Family", selection: Binding(
                    get: { appState.preferences.fontFamily },
                    set: { appState.preferences.fontFamily = $0 }
                )) {
                    ForEach(FontFamily.allCases, id: \.self) { family in
                        Text(family.description).tag(family)
                    }
                }

                Picker("Weight", selection: Binding(
                    get: { appState.preferences.fontWeight },
                    set: { appState.preferences.fontWeight = $0 }
                )) {
                    ForEach(FontWeightOption.allCases, id: \.self) { weight in
                        Text(weight.description).tag(weight)
                    }
                }

                Picker("Alignment", selection: Binding(
                    get: { appState.preferences.timeAlignment },
                    set: { appState.preferences.timeAlignment = $0 }
                )) {
                    ForEach(TimeAlignment.allCases, id: \.self) { alignment in
                        Text(alignment.description).tag(alignment)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Day/Night") {
                Toggle("Show day/night indicators", isOn: Binding(
                    get: { appState.preferences.showDayNightIndicator },
                    set: { appState.preferences.showDayNightIndicator = $0 }
                ))

                Toggle("Use accurate sunrise/sunset", isOn: Binding(
                    get: { appState.preferences.useAccurateSunriseSunset },
                    set: { appState.preferences.useAccurateSunriseSunset = $0 }
                ))
                .disabled(!appState.preferences.showDayNightIndicator)

                if appState.preferences.showDayNightIndicator && appState.preferences.useAccurateSunriseSunset {
                    Text("Calculates actual sunrise/sunset times based on timezone coordinates")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Theme Settings Tab
struct ThemeSettingsTab: View {
    @State private var themeManager = ThemeManager.shared
    @State private var showCreateTheme = false
    @State private var newThemeName = ""
    @State private var newAccentColor = Color.blue
    @State private var newDaytimeColor = Color.yellow
    @State private var newNighttimeColor = Color.indigo

    var body: some View {
        Form {
            Section("Select Theme") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(themeManager.allThemes) { theme in
                        ThemePreviewCard(
                            theme: theme,
                            isSelected: themeManager.currentTheme.id == theme.id,
                            onSelect: {
                                themeManager.setTheme(theme)
                            },
                            onDelete: theme.isBuiltIn ? nil : {
                                themeManager.deleteCustomTheme(theme)
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
            }

            Section("Create Custom Theme") {
                if showCreateTheme {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Theme Name", text: $newThemeName)
                            .textFieldStyle(.roundedBorder)

                        HStack {
                            ColorPicker("Accent", selection: $newAccentColor)
                            ColorPicker("Day", selection: $newDaytimeColor)
                            ColorPicker("Night", selection: $newNighttimeColor)
                        }

                        HStack {
                            Button("Create") {
                                createTheme()
                            }
                            .disabled(newThemeName.isEmpty)

                            Button("Cancel") {
                                showCreateTheme = false
                                resetNewTheme()
                            }
                        }
                    }
                } else {
                    Button {
                        showCreateTheme = true
                    } label: {
                        Label("Create New Theme", systemImage: "plus")
                    }
                }
            }

            Section("Current Theme Colors") {
                HStack(spacing: 16) {
                    VStack {
                        Circle()
                            .fill(themeManager.currentTheme.accentColor)
                            .frame(width: 30, height: 30)
                        Text("Accent")
                            .font(.caption2)
                    }

                    VStack {
                        Circle()
                            .fill(themeManager.currentTheme.daytimeColor)
                            .frame(width: 30, height: 30)
                        Text("Day")
                            .font(.caption2)
                    }

                    VStack {
                        Circle()
                            .fill(themeManager.currentTheme.nighttimeColor)
                            .frame(width: 30, height: 30)
                        Text("Night")
                            .font(.caption2)
                    }

                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func createTheme() {
        let theme = AppTheme(
            name: newThemeName,
            accentColorHex: newAccentColor.toHex() ?? "#007AFF",
            daytimeColorHex: newDaytimeColor.toHex() ?? "#FFD60A",
            nighttimeColorHex: newNighttimeColor.toHex() ?? "#5E5CE6"
        )
        themeManager.addCustomTheme(theme)
        themeManager.setTheme(theme)
        showCreateTheme = false
        resetNewTheme()
    }

    private func resetNewTheme() {
        newThemeName = ""
        newAccentColor = .blue
        newDaytimeColor = .yellow
        newNighttimeColor = .indigo
    }
}

// MARK: - Theme Preview Card
struct ThemePreviewCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: (() -> Void)?

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                // Color preview
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(theme.accentColor)
                    Rectangle()
                        .fill(theme.daytimeColor)
                    Rectangle()
                        .fill(theme.nighttimeColor)
                }
                .frame(height: 30)
                .cornerRadius(4)

                Text(theme.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? theme.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let onDelete = onDelete {
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            }
        }
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
