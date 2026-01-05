//
//  FocusModeService.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation
import Combine
import AppKit

// MARK: - Focus Mode Trigger
enum FocusTrigger: String, Codable, CaseIterable {
    case pomodoro = "Pomodoro Session"
    case meeting = "During Meetings"
    case manual = "Manual"

    var description: String {
        switch self {
        case .pomodoro: return "Automatically enable Focus when starting a Pomodoro work session"
        case .meeting: return "Automatically enable Focus when you're in a calendar meeting"
        case .manual: return "Only enable Focus when you manually toggle it"
        }
    }
}

// MARK: - Focus Mode Settings
struct FocusModeSettings: Codable, Equatable {
    var enableDuringPomodoro: Bool = true
    var enableDuringMeetings: Bool = false
    var shortcutName: String = "MomentumBar Focus"
    var autoDisableAfterSession: Bool = true
    var hasCompletedSetup: Bool = false

    static let `default` = FocusModeSettings()
}

// MARK: - Focus Mode Service
@MainActor
@Observable
final class FocusModeService {
    static let shared = FocusModeService()

    // State
    var isFocusModeActive: Bool = false
    var currentTrigger: FocusTrigger?
    var settings: FocusModeSettings = .default

    // Setup state
    var isSetupComplete: Bool {
        settings.hasCompletedSetup
    }

    private var pomodoroObservation: Any?
    private var calendarObservation: Any?

    private init() {
        loadSettings()
        setupObservers()
    }

    // MARK: - Setup Observers
    private func setupObservers() {
        // Observe Pomodoro state changes
        // We'll integrate this with PomodoroService
    }

    // MARK: - Focus Control

    /// Enable Focus mode via Shortcuts
    func enableFocus(trigger: FocusTrigger) {
        guard settings.hasCompletedSetup else {
            print("Focus Mode: Setup not complete")
            return
        }

        isFocusModeActive = true
        currentTrigger = trigger

        runShortcut(named: settings.shortcutName, action: "on")
    }

    /// Disable Focus mode via Shortcuts
    func disableFocus() {
        guard isFocusModeActive else { return }

        isFocusModeActive = false
        currentTrigger = nil

        runShortcut(named: settings.shortcutName, action: "off")
    }

    /// Toggle Focus mode
    func toggleFocus() {
        if isFocusModeActive {
            disableFocus()
        } else {
            enableFocus(trigger: .manual)
        }
    }

    // MARK: - Pomodoro Integration

    /// Called when Pomodoro work session starts
    func onPomodoroWorkStarted() {
        guard settings.enableDuringPomodoro else { return }
        enableFocus(trigger: .pomodoro)
    }

    /// Called when Pomodoro work session ends or is stopped
    func onPomodoroWorkEnded() {
        guard settings.enableDuringPomodoro && settings.autoDisableAfterSession else { return }
        guard currentTrigger == .pomodoro else { return }
        disableFocus()
    }

    // MARK: - Meeting Integration

    /// Called when a meeting starts
    func onMeetingStarted() {
        guard settings.enableDuringMeetings else { return }
        enableFocus(trigger: .meeting)
    }

    /// Called when a meeting ends
    func onMeetingEnded() {
        guard settings.enableDuringMeetings else { return }
        guard currentTrigger == .meeting else { return }
        disableFocus()
    }

    /// Check if currently in a meeting and update Focus state
    func checkMeetingStatus(events: [CalendarEvent]) {
        guard settings.enableDuringMeetings else { return }

        let isInMeeting = events.contains { $0.isOngoing && !$0.isAllDay }

        if isInMeeting && !isFocusModeActive {
            onMeetingStarted()
        } else if !isInMeeting && currentTrigger == .meeting {
            onMeetingEnded()
        }
    }

    // MARK: - Shortcuts Integration

    private func runShortcut(named name: String, action: String) {
        // Use the shortcuts URL scheme to run the shortcut
        // The shortcut should accept an "action" input parameter
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        let urlString = "shortcuts://run-shortcut?name=\(encodedName)&input=text&text=\(action)"

        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    /// Open Shortcuts app to help user create the required shortcut
    func openShortcutsApp() {
        if let url = URL(string: "shortcuts://") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Mark setup as complete
    func completeSetup() {
        settings.hasCompletedSetup = true
        saveSettings()
    }

    // MARK: - Persistence

    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "com.momentumbar.focusModeSettings"),
           let decoded = try? JSONDecoder().decode(FocusModeSettings.self, from: data) {
            settings = decoded
        }
    }

    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "com.momentumbar.focusModeSettings")
        }
    }

    // MARK: - Setup Instructions

    static let setupInstructions: [(step: Int, title: String, description: String)] = [
        (1, "Open Shortcuts App", "Click the button below to open the Shortcuts app on your Mac."),
        (2, "Create New Shortcut", "Click the '+' button to create a new shortcut and name it 'MomentumBar Focus'."),
        (3, "Add 'Set Focus' Action", "Search for 'Set Focus' and add it to your shortcut."),
        (4, "Configure the Action", "Set the Focus to turn 'On' or use 'Shortcut Input' to control it dynamically."),
        (5, "Add Condition (Optional)", "Add an 'If' action to check if input is 'on' or 'off' for dynamic control."),
        (6, "Save and Return", "Save your shortcut and return to MomentumBar to complete setup.")
    ]

    static let shortcutTemplate = """
    Shortcut Template:

    1. Receive [Shortcut Input] from Share Sheet
    2. If [Shortcut Input] is "on"
       → Set Focus to On
    3. Otherwise
       → Set Focus to Off
    4. End If
    """
}
