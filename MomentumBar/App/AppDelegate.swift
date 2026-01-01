//
//  AppDelegate.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import AppKit
import SwiftUI
import Carbon.HIToolbox

class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarController = MenuBarController()
        setupGlobalHotKey()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
    }

    // MARK: - Global Hot Key (⌘⇧T to toggle popover)
    private func setupGlobalHotKey() {
        // Register for ⌘⇧T (Command + Shift + T)
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x4D424152) // "MBAR" in hex
        hotKeyID.id = 1

        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)

        // Install event handler
        let handlerBlock: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData = userData else { return noErr }
            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            appDelegate.handleHotKey()
            return noErr
        }

        var eventHandler: EventHandlerRef?
        InstallEventHandler(
            GetApplicationEventTarget(),
            handlerBlock,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        // Register the hot key: ⌘⇧T
        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_T)

        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    @objc private func handleHotKey() {
        menuBarController?.togglePopover()
    }
}
