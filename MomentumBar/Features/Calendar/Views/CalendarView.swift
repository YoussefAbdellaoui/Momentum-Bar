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
                // Overlap warning banner
                if calendarService.hasOverlaps {
                    OverlapWarningBanner(overlapCount: calendarService.overlaps.count)
                }

                // Ongoing events
                let ongoingEvents = calendarService.upcomingEvents.filter { $0.isOngoing }
                if !ongoingEvents.isEmpty {
                    Section {
                        ForEach(ongoingEvents) { event in
                            EventRowView(
                                event: event,
                                isOverlapping: calendarService.isOverlapping(event),
                                overlappingEvents: calendarService.getOverlappingEvents(for: event)
                            )
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
                            EventRowView(
                                event: event,
                                isOverlapping: calendarService.isOverlapping(event),
                                overlappingEvents: calendarService.getOverlappingEvents(for: event)
                            )
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

// MARK: - Overlap Warning Banner
struct OverlapWarningBanner: View {
    let overlapCount: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            Text("\(overlapCount) scheduling \(overlapCount == 1 ? "conflict" : "conflicts") detected")
                .font(.caption)
                .fontWeight(.medium)

            Spacer()
        }
        .padding(10)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Event Row View
struct EventRowView: View {
    let event: CalendarEvent
    var isOverlapping: Bool = false
    var overlappingEvents: [CalendarEvent] = []

    @State private var showOverlapDetails = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Calendar color indicator with overlap warning
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: event.calendarColorHex) ?? .blue)
                        .frame(width: 4)

                    if isOverlapping {
                        Circle()
                            .fill(.orange)
                            .frame(width: 8, height: 8)
                            .offset(x: 0, y: -2)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Title row with overlap indicator
                    HStack(spacing: 6) {
                        Text(event.title)
                            .font(.body)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        if isOverlapping {
                            Button {
                                showOverlapDetails.toggle()
                            } label: {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            .buttonStyle(.plain)
                            .help("Scheduling conflict")
                        }
                    }

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

            // Overlap details expandable section
            if showOverlapDetails && !overlappingEvents.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Divider()

                    Text("Conflicts with:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)

                    ForEach(overlappingEvents) { conflictEvent in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(hex: conflictEvent.calendarColorHex) ?? .blue)
                                .frame(width: 3, height: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(conflictEvent.title)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)

                                Text(conflictEvent.timeRange)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 10)
                    }
                }
                .padding(.bottom, 10)
                .background(Color.orange.opacity(0.05))
            }
        }
        .background(isOverlapping ? Color.orange.opacity(0.05) : Color.primary.opacity(0.03))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isOverlapping ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    CalendarView()
        .frame(width: 400, height: 400)
}
