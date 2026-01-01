//
//  MenuBarController.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import AppKit
import SwiftUI
import Combine

class MenuBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var eventMonitor: EventMonitor?
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()

        setupPopover()
        configureStatusButton()
        setupEventMonitor()
        startMenuBarTimer()
        observePreferences()
    }

    deinit {
        timer?.invalidate()
    }

    private func setupPopover() {
        popover.contentSize = NSSize(width: 420, height: 520)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: PopoverContentView())
    }

    private func configureStatusButton() {
        if let button = statusItem.button {
            button.action = #selector(togglePopover)
            button.target = self
            updateMenuBarDisplay()
        }
    }

    private func setupEventMonitor() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let self = self, self.popover.isShown {
                self.closePopover()
            }
        }
    }

    // MARK: - Menu Bar Timer
    private func startMenuBarTimer() {
        // Align to the next second
        let now = Date()
        let nextSecond = ceil(now.timeIntervalSinceReferenceDate)
        let delay = nextSecond - now.timeIntervalSinceReferenceDate

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.updateMenuBarDisplay()
            self?.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                self?.updateMenuBarDisplay()
            }
            if let timer = self?.timer {
                RunLoop.current.add(timer, forMode: .common)
            }
        }
    }

    private func observePreferences() {
        // Observe UserDefaults changes for menu bar display mode
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateMenuBarDisplay()
            }
            .store(in: &cancellables)
    }

    // MARK: - Menu Bar Display
    private func updateMenuBarDisplay() {
        guard let button = statusItem.button else { return }

        let preferences = StorageService.shared.loadPreferences()

        switch preferences.menuBarDisplayMode {
        case .icon:
            button.image = NSImage(systemSymbolName: "clock.fill", accessibilityDescription: "MomentumBar")
            button.title = ""
            button.imagePosition = .imageOnly

        case .time:
            button.image = nil
            button.title = formattedMenuBarTime(preferences: preferences)
            button.imagePosition = .noImage

        case .iconAndTime:
            button.image = NSImage(systemSymbolName: "clock.fill", accessibilityDescription: "MomentumBar")
            button.title = " " + formattedMenuBarTime(preferences: preferences)
            button.imagePosition = .imageLeading
        }

        // Apply monospace font for time display
        if preferences.menuBarDisplayMode != .icon {
            let font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            button.attributedTitle = NSAttributedString(
                string: button.title,
                attributes: [.font: font]
            )
        }
    }

    private func formattedMenuBarTime(preferences: AppPreferences) -> String {
        let formatter = DateFormatter()

        if preferences.use24HourFormat {
            formatter.dateFormat = preferences.showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            formatter.dateFormat = preferences.showSeconds ? "h:mm:ss a" : "h:mm a"
        }

        return formatter.string(from: Date())
    }

    // MARK: - Popover Control
    @objc func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    func showPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            eventMonitor?.start()
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func closePopover() {
        popover.performClose(nil)
        eventMonitor?.stop()
    }
}
