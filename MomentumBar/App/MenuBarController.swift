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
    static var shared: MenuBarController?

    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var eventMonitor: EventMonitor?
    private var timer: Timer?
    private var calendarTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var upcomingMeetingsCount: Int = 0
    private var nextMeeting: CalendarEvent?
    private(set) var isPinned: Bool = false
    private var lastDisplayText: String = ""
    private var lastShowIcon: Bool = false
    private var lastBadgeLabel: String?
    private var currentTimerInterval: TimeInterval = 1.0

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        popover = NSPopover()

        MenuBarController.shared = self

        // Make status item visible
        statusItem.isVisible = true

        setupPopover()
        configureStatusButton()
        setupEventMonitor()
        startMenuBarTimer()
        startCalendarRefreshTimer()
        observePreferences()
        setupNotifications()

        // Load initial pin state
        let preferences = StorageService.shared.loadPreferences()
        isPinned = preferences.keepPopoverPinned
        updatePopoverBehavior()
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
        popover.animates = false  // Disable animations to prevent layout recursion

        let hostingController = NSHostingController(rootView: PopoverContentView())
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        popover.contentViewController = hostingController

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePopoverResize(_:)),
            name: .popoverResizeRequested,
            object: nil
        )
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
        timer?.invalidate()

        let preferences = StorageService.shared.loadPreferences()
        currentTimerInterval = preferences.showSeconds ? 1.0 : 30.0

        // Align to the next second
        let now = Date()
        let nextSecond = ceil(now.timeIntervalSinceReferenceDate)
        let delay = nextSecond - now.timeIntervalSinceReferenceDate

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.updateMenuBarDisplay()
            self?.timer = Timer.scheduledTimer(withTimeInterval: self?.currentTimerInterval ?? 1.0, repeats: true) { [weak self] _ in
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
                guard let self = self else { return }
                let preferences = StorageService.shared.loadPreferences()
                let newInterval = preferences.showSeconds ? 1.0 : 30.0
                if newInterval != self.currentTimerInterval {
                    self.startMenuBarTimer()
                }
                self.updateMenuBarDisplay()
            }
            .store(in: &cancellables)
    }

    // MARK: - Menu Bar Display
    private func updateMenuBarDisplay() {
        guard let button = statusItem.button else { return }
        statusItem.isVisible = true

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

        // Add pinned timezones (skip if icon-only mode)
        if preferences.menuBarDisplayMode != .icon {
            let pinnedDisplay = formattedPinnedTimeZones(preferences: preferences)
            if !pinnedDisplay.isEmpty {
                if displayText.isEmpty {
                    displayText = pinnedDisplay
                } else {
                    displayText += " | " + pinnedDisplay
                }
            }
        }

        // Add next meeting countdown if enabled (works in all modes)
        if preferences.showNextMeetingTime, let next = nextMeeting {
            let minutes = next.minutesUntilStart
            if minutes > 0 && minutes <= 60 {
                let meetingText = "\(minutes)m"
                if displayText.isEmpty {
                    displayText = meetingText
                } else {
                    displayText += " | " + meetingText
                }
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

        if displayText == lastDisplayText && showIcon == lastShowIcon {
            // No UI change needed
        } else {
            button.title = displayText
            lastDisplayText = displayText
            lastShowIcon = showIcon
        }

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
            let badge = "\(upcomingMeetingsCount)"
            if badge != lastBadgeLabel {
                NSApp.dockTile.badgeLabel = badge
                lastBadgeLabel = badge
            }
        } else {
            if lastBadgeLabel != nil {
                NSApp.dockTile.badgeLabel = nil
                lastBadgeLabel = nil
            }
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

    private func formattedPinnedTimeZones(preferences: AppPreferences) -> String {
        let appState = AppState.shared
        let pinnedZones = appState.pinnedTimeZones

        guard !pinnedZones.isEmpty else { return "" }

        let formatter = DateFormatter()
        let separator = preferences.timeSeparator.rawValue

        // Use simplified format for menu bar (no seconds to save space)
        if preferences.use24HourFormat {
            formatter.dateFormat = "HH'\(separator)'mm"
        } else {
            formatter.dateFormat = "h'\(separator)'mm a"
        }

        let timeStrings = pinnedZones.compactMap { entry -> String? in
            guard let tz = entry.timeZone else { return nil }
            formatter.timeZone = tz
            let time = formatter.string(from: Date())
            return "\(entry.shortCityName) \(time)"
        }

        return timeStrings.joined(separator: " | ")
    }

    // MARK: - Popover Control
    @objc func togglePopover() {
        // Check if user can access the app
        guard LicenseService.shared.canUseApp else {
            AppDelegate.shared?.showTrialExpiredWindow()
            return
        }

        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    func showPopover() {
        // Check if user can access the app
        guard LicenseService.shared.canUseApp else {
            AppDelegate.shared?.showTrialExpiredWindow()
            return
        }

        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

            // Only start event monitor if not pinned
            if !isPinned {
                eventMonitor?.start()
            }

            // Activate after popover layout is complete to avoid layout recursion
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    func closePopover() {
        popover.performClose(nil)
        eventMonitor?.stop()
    }

    @objc private func handlePopoverResize(_ notification: Notification) {
        guard let size = notification.object as? NSValue else { return }
        let newSize = size.sizeValue
        if popover.contentSize != newSize {
            popover.contentSize = newSize
        }
    }

    // MARK: - Pin Control

    func togglePin() {
        isPinned.toggle()

        // Save preference
        var preferences = StorageService.shared.loadPreferences()
        preferences.keepPopoverPinned = isPinned
        StorageService.shared.savePreferences(preferences)

        updatePopoverBehavior()

        // Post notification for UI updates
        NotificationCenter.default.post(name: .popoverPinStateChanged, object: nil)
    }

    private func updatePopoverBehavior() {
        if isPinned {
            popover.behavior = .applicationDefined
            eventMonitor?.stop()
        } else {
            popover.behavior = .transient
            if popover.isShown {
                eventMonitor?.start()
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let popoverPinStateChanged = Notification.Name("popoverPinStateChanged")
    static let popoverResizeRequested = Notification.Name("popoverResizeRequested")
}
