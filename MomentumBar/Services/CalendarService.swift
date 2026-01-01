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

    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var availableCalendars: [EKCalendar] = []
    @Published var upcomingEvents: [CalendarEvent] = []
    @Published var isLoading = false

    private init() {
        updateAuthorizationStatus()
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

        return ekEvents.map { CalendarEvent(from: $0) }
    }

    // MARK: - Refresh
    func refresh() {
        guard authorizationStatus == .fullAccess else { return }
        loadCalendars()
        fetchUpcomingEvents()
    }
}
