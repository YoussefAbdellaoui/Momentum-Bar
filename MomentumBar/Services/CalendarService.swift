//
//  CalendarService.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation
import EventKit
import Combine

@MainActor
final class CalendarService: ObservableObject {
    static let shared = CalendarService()

    private let eventStore = EKEventStore()
    private var authCheckTimer: Timer?

    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var availableCalendars: [EKCalendar] = []
    @Published var upcomingEvents: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var overlaps: [MeetingOverlap] = []

    var hasOverlaps: Bool {
        !overlaps.isEmpty
    }

    var overlappingEventIDs: Set<String> {
        Set(overlaps.flatMap { $0.events.map { $0.id } })
    }

    func isOverlapping(_ event: CalendarEvent) -> Bool {
        overlappingEventIDs.contains(event.id)
    }

    func getOverlappingEvents(for event: CalendarEvent) -> [CalendarEvent] {
        OverlapDetector.overlappingEvents(for: event, in: upcomingEvents)
    }

    private init() {
        updateAuthorizationStatus()
        setupNotifications()
        startAuthorizationMonitoring()
    }

    deinit {
        authCheckTimer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup
    private func setupNotifications() {
        // Listen for calendar store changes (events added/modified/deleted)
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.handleCalendarStoreChanged()
            }
        }
    }

    private func startAuthorizationMonitoring() {
        // Periodically check authorization status when not yet granted
        // This catches when user grants permission in System Settings
        authCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.checkAuthorizationChange()
            }
        }
    }

    private func checkAuthorizationChange() {
        let currentStatus = EKEventStore.authorizationStatus(for: .event)
        if currentStatus != authorizationStatus {
            let wasNotAuthorized = authorizationStatus != .fullAccess
            authorizationStatus = currentStatus

            // If we just got authorized, load calendars and events
            if wasNotAuthorized && currentStatus == .fullAccess {
                loadCalendars()
                fetchUpcomingEvents()
            }
        }

        // Stop polling once we have full access
        if currentStatus == .fullAccess {
            authCheckTimer?.invalidate()
            authCheckTimer = nil
        }
    }

    private func handleCalendarStoreChanged() {
        // Refresh data when calendar store changes
        if authorizationStatus == .fullAccess {
            loadCalendars()
            fetchUpcomingEvents()
        }
    }

    // MARK: - Authorization
    func updateAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }

    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                updateAuthorizationStatus()
                if granted {
                    loadCalendars()
                }
            }
            return granted
        } catch {
            print("Calendar access request failed: \(error)")
            return false
        }
    }

    // MARK: - Calendars
    func loadCalendars() {
        guard authorizationStatus == .fullAccess else { return }
        availableCalendars = eventStore.calendars(for: .event)
    }

    // MARK: - Events
    func fetchUpcomingEvents(hours: Int = 24, calendarIDs: Set<String>? = nil) {
        guard authorizationStatus == .fullAccess else { return }

        isLoading = true

        let calendars: [EKCalendar]?
        if let ids = calendarIDs, !ids.isEmpty {
            calendars = availableCalendars.filter { ids.contains($0.calendarIdentifier) }
        } else {
            calendars = nil // All calendars
        }

        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .hour, value: hours, to: startDate) ?? startDate

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: calendars
        )

        let ekEvents = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }

        upcomingEvents = ekEvents.map { CalendarEvent(from: $0) }
        overlaps = OverlapDetector.findOverlaps(in: upcomingEvents)
        isLoading = false
    }

    func fetchRecentEvents(hours: Int = 2) -> [CalendarEvent] {
        guard authorizationStatus == .fullAccess else { return [] }

        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -hours, to: endDate) ?? endDate

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )

        let ekEvents = eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }

        let events = ekEvents.map { CalendarEvent(from: $0) }

        // Record completed meetings for analytics
        MeetingAnalyticsService.shared.recordMeetings(from: events.filter { $0.isPast })

        return events
    }

    /// Record analytics for completed events
    func recordCompletedMeetings() {
        let recentEvents = fetchRecentEvents(hours: 24)
        MeetingAnalyticsService.shared.recordMeetings(from: recentEvents.filter { $0.isPast })
    }

    // MARK: - Refresh
    func refresh() {
        guard authorizationStatus == .fullAccess else { return }
        loadCalendars()
        fetchUpcomingEvents()
    }
}
