//
//  AppDelegate.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import AppKit
import SwiftUI
import Carbon.HIToolbox
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?

    private var menuBarController: MenuBarController?
    private var hotKeyRefs: [EventHotKeyRef] = []
    private var eventHandler: EventHandlerRef?
    private var cancellables = Set<AnyCancellable>()
    private var trialExpiredWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // Apply dock icon preference
        applyDockIconPreference()

        menuBarController = MenuBarController()
        setupGlobalHotKeys()
        observePreferences()

        // Show onboarding for first-time users
        OnboardingWindowController.shared.showOnboardingIfNeeded()

        // Validate license at launch
        Task { @MainActor in
            await validateLicense()
        }

        // Record meeting analytics on app activation
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.recordMeetingAnalytics()
        }
    }

    // MARK: - Meeting Analytics

    private func recordMeetingAnalytics() {
        Task { @MainActor in
            CalendarService.shared.recordCompletedMeetings()
        }
    }

    // MARK: - License Validation

    @MainActor
    private func validateLicense() async {
        let licenseService = LicenseService.shared
        await licenseService.validateAtLaunch()

        // Check if trial expired and show modal
        if case .expired = licenseService.currentStatus {
            showTrialExpiredWindow()
        }
    }

    func showTrialExpiredWindow() {
        // Create window if it doesn't exist
        if trialExpiredWindow == nil {
            let contentView = TrialExpiredView()
            let hostingController = NSHostingController(rootView: contentView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "License Required"
            window.styleMask = [.titled] // No closable - user must activate or quit
            window.isReleasedWhenClosed = false
            window.center()
            window.level = .floating // Keep above other windows
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            // Prevent window from being closed via keyboard shortcut
            window.standardWindowButton(.closeButton)?.isHidden = true

            trialExpiredWindow = window
        }

        trialExpiredWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeTrialExpiredWindow() {
        trialExpiredWindow?.close()
        trialExpiredWindow = nil
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        unregisterAllHotKeys()
    }

    // MARK: - Dock Icon Management

    private func applyDockIconPreference() {
        let preferences = StorageService.shared.loadPreferences()
        setDockIconVisible(!preferences.hideDockIcon)
    }

    func setDockIconVisible(_ visible: Bool) {
        if visible {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    private func observePreferences() {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyDockIconPreference()
            }
            .store(in: &cancellables)
    }

    // MARK: - Global Hot Keys

    private func setupGlobalHotKeys() {
        unregisterAllHotKeys()

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)

        // Install event handler
        let handlerBlock: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData = userData,
                  let event = event else { return noErr }

            var hotKeyID = EventHotKeyID()
            GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            appDelegate.handleHotKey(id: hotKeyID.id)
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            handlerBlock,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        let preferences = StorageService.shared.loadPreferences()

        // Register toggle popover hotkey (ID: 1)
        registerHotKey(
            preferences.togglePopoverShortcut,
            id: 1,
            signature: 0x4D424152 // "MBAR"
        )

        // Register add timezone hotkey (ID: 2)
        registerHotKey(
            preferences.addTimeZoneShortcut,
            id: 2,
            signature: 0x4D424152
        )

        // Register settings hotkey (ID: 3)
        registerHotKey(
            preferences.openSettingsShortcut,
            id: 3,
            signature: 0x4D424152
        )
    }

    private func registerHotKey(_ shortcut: KeyboardShortcut, id: UInt32, signature: OSType) {
        guard !shortcut.key.isEmpty else { return }

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = signature
        hotKeyID.id = id

        let modifiers = carbonModifiers(from: shortcut.modifiers)
        guard let keyCode = keyCodeFromString(shortcut.key) else { return }

        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status == noErr, let ref = hotKeyRef {
            hotKeyRefs.append(ref)
        }
    }

    private func unregisterAllHotKeys() {
        for ref in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
    }

    private func handleHotKey(id: UInt32) {
        // Block hotkeys when trial is expired
        guard LicenseService.shared.canUseApp else {
            showTrialExpiredWindow()
            return
        }

        switch id {
        case 1:
            menuBarController?.togglePopover()
        case 2:
            menuBarController?.showPopover()
            AppState.shared.isAddingTimeZone = true
        case 3:
            openSettings()
        default:
            break
        }
    }

    private func openSettings() {
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func carbonModifiers(from modifiers: Set<KeyboardShortcut.Modifier>) -> UInt32 {
        var result: UInt32 = 0
        if modifiers.contains(.command) { result |= UInt32(cmdKey) }
        if modifiers.contains(.shift) { result |= UInt32(shiftKey) }
        if modifiers.contains(.option) { result |= UInt32(optionKey) }
        if modifiers.contains(.control) { result |= UInt32(controlKey) }
        return result
    }

    private func keyCodeFromString(_ key: String) -> UInt32? {
        let keyMap: [String: Int] = [
            "A": kVK_ANSI_A, "B": kVK_ANSI_B, "C": kVK_ANSI_C, "D": kVK_ANSI_D,
            "E": kVK_ANSI_E, "F": kVK_ANSI_F, "G": kVK_ANSI_G, "H": kVK_ANSI_H,
            "I": kVK_ANSI_I, "J": kVK_ANSI_J, "K": kVK_ANSI_K, "L": kVK_ANSI_L,
            "M": kVK_ANSI_M, "N": kVK_ANSI_N, "O": kVK_ANSI_O, "P": kVK_ANSI_P,
            "Q": kVK_ANSI_Q, "R": kVK_ANSI_R, "S": kVK_ANSI_S, "T": kVK_ANSI_T,
            "U": kVK_ANSI_U, "V": kVK_ANSI_V, "W": kVK_ANSI_W, "X": kVK_ANSI_X,
            "Y": kVK_ANSI_Y, "Z": kVK_ANSI_Z,
            "0": kVK_ANSI_0, "1": kVK_ANSI_1, "2": kVK_ANSI_2, "3": kVK_ANSI_3,
            "4": kVK_ANSI_4, "5": kVK_ANSI_5, "6": kVK_ANSI_6, "7": kVK_ANSI_7,
            "8": kVK_ANSI_8, "9": kVK_ANSI_9,
            ",": kVK_ANSI_Comma, ".": kVK_ANSI_Period, "/": kVK_ANSI_Slash,
            ";": kVK_ANSI_Semicolon, "'": kVK_ANSI_Quote,
            "[": kVK_ANSI_LeftBracket, "]": kVK_ANSI_RightBracket,
            "-": kVK_ANSI_Minus, "=": kVK_ANSI_Equal,
            "`": kVK_ANSI_Grave, "\\": kVK_ANSI_Backslash
        ]
        return keyMap[key.uppercased()].map { UInt32($0) }
    }
}
