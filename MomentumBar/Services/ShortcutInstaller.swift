//
//  ShortcutInstaller.swift
//  MomentumBar
//
//  Automatically installs Focus Mode shortcuts without manual user intervention
//

import Foundation
import AppKit

/// Handles automatic installation of Focus Mode shortcuts
@MainActor
@Observable
final class ShortcutInstaller {
    static let shared = ShortcutInstaller()

    // State
    var isInstalling: Bool = false
    var installationProgress: String = ""
    var hasInstalledShortcuts: Bool {
        UserDefaults.standard.bool(forKey: "com.momentumbar.shortcutsInstalled")
    }

    // GitHub repo where shortcuts are hosted
    private let shortcutsBaseURL = "https://raw.githubusercontent.com/YoussefAbdellaoui/Momentum-Bar/main/Shortcuts"

    // All available Focus mode shortcuts
    private let availableShortcuts = [
        "MomentumBar Do Not Disturb",
        "MomentumBar Work",
        "MomentumBar Personal",
        "MomentumBar Sleep",
        "MomentumBar Focus Off"
    ]

    // Minimum required shortcuts (always installed)
    private let requiredShortcuts = [
        "MomentumBar Do Not Disturb",
        "MomentumBar Focus Off"
    ]

    private init() {}

    // MARK: - Auto Installation

    /// Automatically install all required shortcuts
    func autoInstallShortcuts() async -> Bool {
        guard !hasInstalledShortcuts else {
            print("[ShortcutInstaller] Shortcuts already installed")
            return true
        }

        isInstalling = true
        installationProgress = "Installing Focus Mode shortcuts..."

        defer {
            isInstalling = false
        }

        // Install each shortcut
        for shortcutName in requiredShortcuts {
            installationProgress = "Installing \(shortcutName)..."

            let success = await installShortcut(named: shortcutName)
            if !success {
                print("[ShortcutInstaller] Failed to install \(shortcutName)")
                // Continue anyway - don't block on failures
            }

            // Small delay to avoid overwhelming the Shortcuts app
            try? await Task.sleep(for: .seconds(1))
        }

        // Mark as installed
        UserDefaults.standard.set(true, forKey: "com.momentumbar.shortcutsInstalled")
        installationProgress = "Installation complete!"

        return true
    }

    /// Install shortcuts for specific Focus modes (detected on user's system)
    func installShortcutsForDetectedModes(_ modes: [SystemFocusMode]) async -> Bool {
        isInstalling = true
        installationProgress = "Installing shortcuts for your Focus modes..."

        defer {
            isInstalling = false
        }

        var installedCount = 0

        // Install Focus Off (always needed)
        if !shortcutExists(named: "MomentumBar Focus Off") {
            installationProgress = "Installing MomentumBar Focus Off..."
            let success = await installShortcut(named: "MomentumBar Focus Off")
            if success {
                installedCount += 1
            }
            try? await Task.sleep(for: .seconds(1))
        }

        // Install shortcut for each detected Focus mode
        for mode in modes {
            let shortcutName = shortcutNameForMode(mode)

            // Skip if already installed
            if shortcutExists(named: shortcutName) {
                print("[ShortcutInstaller] Shortcut already exists: \(shortcutName)")
                continue
            }

            installationProgress = "Installing \(shortcutName)..."

            let success = await installShortcut(named: shortcutName)
            if success {
                installedCount += 1
            } else {
                print("[ShortcutInstaller] Failed to install \(shortcutName)")
            }

            // Small delay between installations
            try? await Task.sleep(for: .seconds(1))
        }

        installationProgress = "Installed \(installedCount) shortcuts!"

        // Mark as installed if we got at least the basics
        if installedCount > 0 {
            UserDefaults.standard.set(true, forKey: "com.momentumbar.shortcutsInstalled")
        }

        return installedCount > 0
    }

    /// Get the shortcut name for a Focus mode
    private func shortcutNameForMode(_ mode: SystemFocusMode) -> String {
        "MomentumBar \(mode.displayName)"
    }

    /// Install a single shortcut by name
    private func installShortcut(named name: String) async -> Bool {
        // Build URL to hosted shortcut file
        let filename = name.replacingOccurrences(of: " ", with: "-")
        let shortcutURL = "\(shortcutsBaseURL)/\(filename).shortcut"

        // Encode URL for shortcuts:// scheme
        guard let encodedURL = shortcutURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let importURL = URL(string: "shortcuts://import-shortcut?url=\(encodedURL)&name=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            return false
        }

        // Open the import URL
        return NSWorkspace.shared.open(importURL)
    }

    // MARK: - Manual Installation

    /// Open Shortcuts app for manual setup (fallback)
    func openShortcutsForManualSetup() {
        if let url = URL(string: "shortcuts://") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Check if shortcuts are actually installed
    func verifyInstallation() -> Bool {
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
                // Check if all required shortcuts are present
                for shortcutName in requiredShortcuts {
                    if !output.contains(shortcutName) {
                        return false
                    }
                }
                return true
            }
        } catch {
            print("[ShortcutInstaller] Error verifying shortcuts: \(error)")
        }

        return false
    }

    /// Check if a specific shortcut exists
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
            print("[ShortcutInstaller] Error checking shortcut: \(error)")
        }

        return false
    }

    /// Get which Focus modes have installed shortcuts
    func getInstalledFocusModes() -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["list"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        var installedModes: [String] = []

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let shortcuts = output.components(separatedBy: .newlines)

                for shortcut in shortcuts {
                    if shortcut.hasPrefix("MomentumBar ") && shortcut != "MomentumBar Focus Off" {
                        // Extract mode name
                        let modeName = shortcut.replacingOccurrences(of: "MomentumBar ", with: "")
                        installedModes.append(modeName)
                    }
                }
            }
        } catch {
            print("[ShortcutInstaller] Error getting installed modes: \(error)")
        }

        return installedModes
    }

    /// Reset installation state (for testing)
    func resetInstallationState() {
        UserDefaults.standard.removeObject(forKey: "com.momentumbar.shortcutsInstalled")
    }
}
