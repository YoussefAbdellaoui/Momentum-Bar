//
//  MenuBarController.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import AppKit
import SwiftUI
import Combine
import EventKit

class MenuBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var eventMonitor: EventMonitor?
    private var timer: Timer?
    private var calendarTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var upcomingMeetingsCount: Int = 0
    private var nextMeeting: CalendarEvent?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()

        setupPopover()
        configureStatusButton()
        setupEventMonitor()
        startMenuBarTimer()
        startCalendarRefreshTimer()
        observePreferences()
        setupNotifications()
    }

    deinit {
        timer?.invalidate()
        calendarTimer?.invalidate()
    }

    private func setupNotifications() {
        Task { @MainActor in
            NotificationService.shared.setupNotificationCategories()
        }
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

    private func startCalendarRefreshTimer() {
        // Refresh calendar every 60 seconds
        calendarTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.refreshCalendarData()
        }
        if let timer = calendarTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
        // Initial refresh
        refreshCalendarData()
    }

    private func refreshCalendarData() {
        Task { @MainActor in
            let service = CalendarService.shared
            guard service.authorizationStatus == .fullAccess else { return }

            service.fetchUpcomingEvents(hours: 24)

            // Update meeting count and next meeting
            let events = service.upcomingEvents.filter { !$0.isAllDay && $0.isUpcoming }
            self.upcomingMeetingsCount = events.count
            self.nextMeeting = events.first

            // Schedule notifications for upcoming meetings
            let preferences = StorageService.shared.loadPreferences()
            if preferences.showMeetingReminders {
                await NotificationService.shared.scheduleReminders(
                    for: events,
                    minutesBefore: preferences.meetingReminderMinutes
                )
            }

            // Update menu bar display
            self.updateMenuBarDisplay()
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

        // Build the display string
        var displayText = ""
        var showIcon = false

        switch preferences.menuBarDisplayMode {
        case .icon:
            showIcon = true

        case .time:
            displayText = formattedMenuBarTime(preferences: preferences)

        case .iconAndTime:
            showIcon = true
            displayText = " " + formattedMenuBarTime(preferences: preferences)
        }

        // Add next meeting time if enabled
        if preferences.showNextMeetingTime, let next = nextMeeting {
            let minutes = next.minutesUntilStart
            if minutes <= 60 {
                displayText += " | \(minutes)m"
            }
        }

        // Configure button
        if showIcon {
            button.image = NSImage(systemSymbolName: "clock.fill", accessibilityDescription: "MomentumBar")
            button.imagePosition = displayText.isEmpty ? .imageOnly : .imageLeading
        } else {
            button.image = nil
            button.imagePosition = .noImage
        }

        button.title = displayText

        // Apply font for time display
        if !displayText.isEmpty {
            let font = menuBarFont(for: preferences)
            button.attributedTitle = NSAttributedString(
                string: displayText,
                attributes: [.font: font]
            )
        }

        // Update app badge for meeting count
        if preferences.showMeetingBadge && upcomingMeetingsCount > 0 {
            NSApp.dockTile.badgeLabel = "\(upcomingMeetingsCount)"
        } else {
            NSApp.dockTile.badgeLabel = nil
        }
    }

    private func menuBarFont(for preferences: AppPreferences) -> NSFont {
        let size = NSFont.systemFontSize
        let weight = nsFontWeight(from: preferences.fontWeight)

        // Use custom font if specified
        if let fontName = preferences.fontFamily.fontName,
           let customFont = NSFont(name: fontName, size: size) {
            return customFont
        }

        // Default to monospaced digits system font
        return NSFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
    }

    private func nsFontWeight(from weight: FontWeightOption) -> NSFont.Weight {
        switch weight {
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }

    private func formattedMenuBarTime(preferences: AppPreferences) -> String {
        let formatter = DateFormatter()
        let separator = preferences.timeSeparator.rawValue

        if preferences.use24HourFormat {
            if preferences.showSeconds {
                formatter.dateFormat = "HH'\(separator)'mm'\(separator)'ss"
            } else {
                formatter.dateFormat = "HH'\(separator)'mm"
            }
        } else {
            if preferences.showSeconds {
                formatter.dateFormat = "h'\(separator)'mm'\(separator)'ss a"
            } else {
                formatter.dateFormat = "h'\(separator)'mm a"
            }
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
