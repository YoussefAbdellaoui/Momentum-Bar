//
//  CalendarView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI
import EventKit

struct CalendarView: View {
    @State private var calendarService = CalendarService.shared
    @State private var appState = AppState.shared

    var body: some View {
        VStack(spacing: 0) {
            switch calendarService.authorizationStatus {
            case .notDetermined:
                requestAccessView

            case .restricted, .denied:
                deniedAccessView

            case .fullAccess, .writeOnly:
                if calendarService.upcomingEvents.isEmpty && !calendarService.isLoading {
                    noEventsView
                } else {
                    eventsList
                }

            @unknown default:
                requestAccessView
            }
        }
        .onAppear {
            calendarService.updateAuthorizationStatus()
            if calendarService.authorizationStatus == .fullAccess {
                calendarService.refresh()
            }
        }
    }

    // MARK: - Request Access View
    private var requestAccessView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Calendar Access")
                .font(.title3)
                .fontWeight(.medium)

            Text("Allow MomentumBar to access your calendar to show upcoming meetings")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Grant Access") {
                Task {
                    await calendarService.requestAccess()
                }
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Denied Access View
    private var deniedAccessView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Calendar Access Denied")
                .font(.title3)
                .fontWeight(.medium)

            Text("Open System Settings to grant calendar access to MomentumBar")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Open System Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - No Events View
    private var noEventsView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Upcoming Events")
                .font(.title3)
                .fontWeight(.medium)

            Text("You have no events in the next 24 hours")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Refresh") {
                calendarService.refresh()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Events List
    private var eventsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                // Ongoing events
                let ongoingEvents = calendarService.upcomingEvents.filter { $0.isOngoing }
                if !ongoingEvents.isEmpty {
                    Section {
                        ForEach(ongoingEvents) { event in
                            EventRowView(event: event)
                        }
                    } header: {
                        SectionHeader(title: "Now")
                    }
                }

                // Upcoming events
                let upcomingEvents = calendarService.upcomingEvents.filter { $0.isUpcoming }
                if !upcomingEvents.isEmpty {
                    Section {
                        ForEach(upcomingEvents) { event in
                            EventRowView(event: event)
                        }
                    } header: {
                        SectionHeader(title: "Upcoming")
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

// MARK: - Event Row View
struct EventRowView: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            // Calendar color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: event.calendarColorHex) ?? .blue)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(event.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                // Time
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)

                    Text(event.timeRange)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                // Progress bar for ongoing events
                if event.isOngoing {
                    ProgressView(value: event.progress)
                        .tint(.blue)
                }
            }

            Spacer()

            // Meeting link button
            if let meetingLink = event.meetingLink {
                Button {
                    NSWorkspace.shared.open(meetingLink.url)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: meetingLink.platform.iconName)
                        Text("Join")
                    }
                    .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            // Time until event
            if event.isUpcoming && event.minutesUntilStart <= 60 {
                Text("in \(event.minutesUntilStart)m")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(8)
    }
}

#Preview {
    CalendarView()
        .frame(width: 400, height: 400)
}
