//
//  FocusModeService.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation
import Combine
import AppKit

// MARK: - System Focus Mode
struct SystemFocusMode: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let symbol: String?

    var displayName: String {
        name.isEmpty ? "Do Not Disturb" : name
    }

    var systemImage: String {
        // Map common focus modes to SF Symbols
        switch name.lowercased() {
        case "do not disturb", "": return "moon.fill"
        case "work": return "briefcase.fill"
        case "personal": return "person.fill"
        case "sleep": return "bed.double.fill"
        case "driving": return "car.fill"
        case "fitness": return "figure.run"
        case "gaming": return "gamecontroller.fill"
        case "reading": return "book.fill"
        case "mindfulness": return "brain.head.profile"
        default: return symbol ?? "moon.fill"
        }
    }

    // Standard Do Not Disturb mode
    static let doNotDisturb = SystemFocusMode(id: "com.apple.donotdisturb.mode.default", name: "Do Not Disturb", symbol: "moon.fill")
}

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
    var selectedFocusModeId: String = SystemFocusMode.doNotDisturb.id
    var autoDisableAfterSession: Bool = true
    var hasCompletedSetup: Bool = false
    var installedShortcuts: [String] = []

    static let `default` = FocusModeSettings()

    // Custom decoder to handle migration from old data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        enableDuringPomodoro = try container.decodeIfPresent(Bool.self, forKey: .enableDuringPomodoro) ?? true
        enableDuringMeetings = try container.decodeIfPresent(Bool.self, forKey: .enableDuringMeetings) ?? false
        selectedFocusModeId = try container.decodeIfPresent(String.self, forKey: .selectedFocusModeId) ?? SystemFocusMode.doNotDisturb.id
        autoDisableAfterSession = try container.decodeIfPresent(Bool.self, forKey: .autoDisableAfterSession) ?? true
        hasCompletedSetup = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedSetup) ?? false
        installedShortcuts = try container.decodeIfPresent([String].self, forKey: .installedShortcuts) ?? []
    }

    init() {
        // Default initializer
    }

    private enum CodingKeys: String, CodingKey {
        case enableDuringPomodoro, enableDuringMeetings, selectedFocusModeId
        case autoDisableAfterSession, hasCompletedSetup, installedShortcuts
    }
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
    var availableFocusModes: [SystemFocusMode] = []
    var currentFocusMode: SystemFocusMode?
    var isLoading: Bool = false
    var lastError: String?

    // Setup state
    var isSetupComplete: Bool {
        settings.hasCompletedSetup
    }

    var selectedFocusMode: SystemFocusMode? {
        availableFocusModes.first { $0.id == settings.selectedFocusModeId }
    }

    private init() {
        loadSettings()
        loadAvailableFocusModes()
        checkCurrentFocusStatus()
    }

    // MARK: - Load System Focus Modes

    /// Read Focus modes from macOS system files
    func loadAvailableFocusModes() {
        var modes: [SystemFocusMode] = []

        // Always include Do Not Disturb as the default
        modes.append(.doNotDisturb)

        // Try to read custom Focus modes from system
        let configPath = NSHomeDirectory() + "/Library/DoNotDisturb/DB/ModeConfigurations.json"

        if let data = FileManager.default.contents(atPath: configPath),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let modeConfigs = json["data"] as? [[String: Any]] {

            for config in modeConfigs {
                if let mode = config["mode"] as? [String: Any],
                   let id = mode["identifier"] as? String,
                   let name = mode["name"] as? String {
                    // Skip the default DND mode as we already added it
                    if id != "com.apple.donotdisturb.mode.default" {
                        let symbol = mode["symbolImageName"] as? String
                        modes.append(SystemFocusMode(id: id, name: name, symbol: symbol))
                    }
                }
            }
        }

        availableFocusModes = modes
    }

    /// Check if a Focus mode is currently active
    func checkCurrentFocusStatus() {
        let assertionsPath = NSHomeDirectory() + "/Library/DoNotDisturb/DB/Assertions.json"

        if let data = FileManager.default.contents(atPath: assertionsPath),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let storeData = json["data"] as? [[String: Any]] {

            // Check if any assertions are active
            for assertion in storeData {
                if let storeAssertionRecords = assertion["storeAssertionRecords"] as? [[String: Any]] {
                    for record in storeAssertionRecords {
                        if let assertionDetails = record["assertionDetails"] as? [String: Any],
                           let modeId = assertionDetails["assertionDetailsModeIdentifier"] as? String {
                            currentFocusMode = availableFocusModes.first { $0.id == modeId }
                            isFocusModeActive = true
                            return
                        }
                    }
                }
            }
        }

        currentFocusMode = nil
        isFocusModeActive = false
    }

    // MARK: - Focus Control

    /// Enable a specific Focus mode
    func enableFocus(mode: SystemFocusMode, trigger: FocusTrigger = .manual) {
        let shortcutName = shortcutName(for: mode)

        // Check if shortcut exists
        guard shortcutExists(named: shortcutName) else {
            lastError = "Shortcut '\(shortcutName)' not found. Please set it up first."
            return
        }

        isFocusModeActive = true
        currentTrigger = trigger
        currentFocusMode = mode
        lastError = nil

        runShortcut(named: shortcutName)
    }

    /// Enable Focus using the selected mode from settings
    func enableFocus(trigger: FocusTrigger = .manual) {
        guard let mode = selectedFocusMode else {
            lastError = "No Focus mode selected"
            return
        }
        enableFocus(mode: mode, trigger: trigger)
    }

    /// Disable Focus mode
    func disableFocus() {
        let shortcutName = "MomentumBar Focus Off"

        guard shortcutExists(named: shortcutName) else {
            lastError = "Shortcut '\(shortcutName)' not found. Please set it up first."
            return
        }

        isFocusModeActive = false
        currentTrigger = nil
        currentFocusMode = nil
        lastError = nil

        runShortcut(named: shortcutName)
    }

    /// Toggle Focus mode
    func toggleFocus() {
        if isFocusModeActive {
            disableFocus()
        } else {
            enableFocus(trigger: .manual)
        }
    }

    /// Toggle a specific Focus mode
    func toggleFocus(mode: SystemFocusMode) {
        if isFocusModeActive && currentFocusMode?.id == mode.id {
            disableFocus()
        } else {
            enableFocus(mode: mode, trigger: .manual)
        }
    }

    // MARK: - Pomodoro Integration

    func onPomodoroWorkStarted() {
        guard settings.enableDuringPomodoro else { return }
        enableFocus(trigger: .pomodoro)
    }

    func onPomodoroWorkEnded() {
        guard settings.enableDuringPomodoro && settings.autoDisableAfterSession else { return }
        guard currentTrigger == .pomodoro else { return }
        disableFocus()
    }

    // MARK: - Meeting Integration

    func onMeetingStarted() {
        guard settings.enableDuringMeetings else { return }
        enableFocus(trigger: .meeting)
    }

    func onMeetingEnded() {
        guard settings.enableDuringMeetings else { return }
        guard currentTrigger == .meeting else { return }
        disableFocus()
    }

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

    /// Get the shortcut name for a Focus mode
    func shortcutName(for mode: SystemFocusMode) -> String {
        "MomentumBar \(mode.displayName)"
    }

    /// Check if a shortcut exists
    func shortcutExists(named name: String) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["list"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.contains(name)
            }
        } catch {
            print("Error checking shortcuts: \(error)")
        }

        return false
    }

    /// Get list of all installed shortcuts
    func getInstalledShortcuts() -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["list"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.components(separatedBy: .newlines).filter { !$0.isEmpty }
            }
        } catch {
            print("Error listing shortcuts: \(error)")
        }

        return []
    }

    /// Run a shortcut using the command line (more reliable than URL scheme)
    private func runShortcut(named name: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
            process.arguments = ["run", name]
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice

            do {
                try process.run()
                // Don't wait - let it run in background
            } catch {
                DispatchQueue.main.async {
                    self.lastError = "Failed to run shortcut: \(error.localizedDescription)"
                }
            }
        }
    }

    /// Open Shortcuts app
    func openShortcutsApp() {
        if let url = URL(string: "shortcuts://") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Open Shortcuts app to create a specific shortcut
    func openShortcutsToCreate(for mode: SystemFocusMode) {
        // Open Shortcuts app - user will need to create manually
        // In the future, we could potentially use URL schemes to pre-fill
        openShortcutsApp()
    }

    // MARK: - Setup

    /// Check which shortcuts need to be created
    func getMissingShortcuts() -> [SystemFocusMode] {
        let installed = getInstalledShortcuts()
        return availableFocusModes.filter { mode in
            !installed.contains(shortcutName(for: mode))
        }
    }

    /// Check if the "Focus Off" shortcut exists
    func hasDisableShortcut() -> Bool {
        shortcutExists(named: "MomentumBar Focus Off")
    }

    /// Mark setup as complete
    func completeSetup() {
        settings.hasCompletedSetup = true
        saveSettings()
    }

    /// Select a Focus mode
    func selectFocusMode(_ mode: SystemFocusMode) {
        settings.selectedFocusModeId = mode.id
        saveSettings()
    }

    // MARK: - Persistence

    private func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: "com.momentumbar.focusModeSettings") else {
            return
        }

        do {
            let decoded = try JSONDecoder().decode(FocusModeSettings.self, from: data)
            settings = decoded
        } catch {
            // If decoding fails, clear corrupted data and use defaults
            print("Failed to decode FocusModeSettings, resetting to defaults: \(error)")
            UserDefaults.standard.removeObject(forKey: "com.momentumbar.focusModeSettings")
        }
    }

    func saveSettings() {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: "com.momentumbar.focusModeSettings")
        } catch {
            print("Failed to save FocusModeSettings: \(error)")
        }
    }

    /// Update a setting safely
    func updateSettings(_ update: (inout FocusModeSettings) -> Void) {
        update(&settings)
        saveSettings()
    }

    // MARK: - Setup Instructions

    static func setupInstructions(for mode: SystemFocusMode) -> [(step: Int, title: String, description: String)] {
        [
            (1, "Open Shortcuts App", "Click the button below to open the Shortcuts app."),
            (2, "Create New Shortcut", "Click '+' and name it 'MomentumBar \(mode.displayName)'."),
            (3, "Add 'Set Focus' Action", "Search for 'Set Focus' and add it."),
            (4, "Select '\(mode.displayName)'", "Choose '\(mode.displayName)' from the Focus dropdown."),
            (5, "Set Duration", "Set 'Until Turned Off' for the duration."),
            (6, "Save", "Save the shortcut and return here.")
        ]
    }

    static let disableShortcutInstructions: [(step: Int, title: String, description: String)] = [
        (1, "Open Shortcuts App", "Click the button below to open the Shortcuts app."),
        (2, "Create New Shortcut", "Click '+' and name it 'MomentumBar Focus Off'."),
        (3, "Add 'Set Focus' Action", "Search for 'Set Focus' and add it."),
        (4, "Select 'Turn Off'", "Set the action to turn Focus 'Off'."),
        (5, "Save", "Save the shortcut and return here.")
    ]
}
