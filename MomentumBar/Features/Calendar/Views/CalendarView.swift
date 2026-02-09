//
//  CalendarView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI
import EventKit

struct CalendarView: View {
    @StateObject private var calendarService = CalendarService.shared
    @State private var appState = AppState.shared
    @State private var showingEventEditor = false
    @State private var showingQuickCreator = false
    @State private var showingICSManager = false
    @State private var editingEvent: CalendarEvent?

    var body: some View {
        VStack(spacing: 0) {
            if !EntitlementService.shared.hasCalendarAccessEntitlement {
                calendarEntitlementMissingView
            } else {
                switch calendarService.authorizationStatus {
            case .notDetermined:
                requestAccessView

            case .restricted, .denied:
                deniedAccessView

            case .fullAccess:
                if calendarService.upcomingEvents.isEmpty && !calendarService.isLoading {
                    noEventsView
                } else {
                    eventsList
                }

                // Bottom toolbar
                calendarToolbar
            case .writeOnly:
                writeOnlyView
            case .authorized:
                legacyAccessView

            @unknown default:
                requestAccessView
                }
            }
        }
        .onAppear {
            calendarService.updateAuthorizationStatus()
            if calendarService.authorizationStatus == .fullAccess || (!isMacOS14OrNewer && calendarService.authorizationStatus == .authorized) {
                calendarService.refresh()
            }
        }
        .sheet(isPresented: $showingEventEditor) {
            EventEditorView(mode: .create, isPresented: $showingEventEditor)
        }
        .sheet(isPresented: $showingQuickCreator) {
            QuickEventCreator(isPresented: $showingQuickCreator)
        }
        .sheet(isPresented: $showingICSManager) {
            ICSManagerView(isPresented: $showingICSManager)
        }
        .sheet(item: $editingEvent) { event in
            EventEditorView(mode: .edit(event), isPresented: .init(
                get: { editingEvent != nil },
                set: { if !$0 { editingEvent = nil } }
            ))
        }
    }

    private var calendarEntitlementMissingView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Calendar Unavailable")
                .font(.title3)
                .fontWeight(.medium)

            Text("This build doesn’t include the calendar entitlement. Please reinstall the official DMG build to enable calendar access.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var legacyAccessView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Calendar Access Granted")
                .font(.title3)
                .fontWeight(.medium)

            Text("MomentumBar can read your calendar. If you don't see events, try Refresh.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Refresh") {
                calendarService.refresh()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var isMacOS14OrNewer: Bool {
        if #available(macOS 14.0, *) {
            return true
        }
        return false
    }

    private var writeOnlyView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("Calendar Access Limited")
                .font(.title3)
                .fontWeight(.medium)

            Text("MomentumBar has write-only access and cannot display your events. Allow full access in System Settings.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Open System Settings") {
                calendarService.openCalendarSystemSettings()
            }
            .buttonStyle(.borderedProminent)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    // MARK: - Delete Event
    private func deleteEvent(_ event: CalendarEvent) {
        do {
            try calendarService.deleteEvent(event)
        } catch {
            print("Failed to delete event: \(error)")
        }
    }

    // MARK: - Calendar Toolbar
    private var calendarToolbar: some View {
        HStack(spacing: 12) {
            // Quick create button
            Button {
                showingQuickCreator = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                    Text("Quick Event")
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)

            Spacer()

            if let lastSyncAt = calendarService.lastSyncAt {
                Text("Updated \(lastSyncAt, style: .time)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else if calendarService.isLoading {
                Text("Updating…")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Button {
                calendarService.refresh()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.body)
            }
            .buttonStyle(.plain)
            .help("Refresh")

            // More options menu
            Menu {
                Button {
                    showingEventEditor = true
                } label: {
                    Label("New Event...", systemImage: "calendar.badge.plus")
                }

                Divider()

                Button {
                    showingICSManager = true
                } label: {
                    Label("Import / Export...", systemImage: "arrow.up.arrow.down")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(width: 24)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.02))
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
                    await calendarService.requestAccessOrOpenSettings()
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
                calendarService.openCalendarSystemSettings()
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

            Text("You have no events in the next 7 days")
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
                if let error = calendarService.lastErrorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(10)
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }

                // Warning banners
                if calendarService.hasOverlaps {
                    OverlapWarningBanner(overlapCount: calendarService.overlaps.count)
                }

                if calendarService.hasBufferWarnings {
                    BufferWarningBanner(warningCount: calendarService.bufferWarningCount)
                }

                // Ongoing events
                let ongoingEvents = calendarService.upcomingEvents.filter { $0.isOngoing }
                if !ongoingEvents.isEmpty {
                    Section {
                        ForEach(ongoingEvents) { event in
                            EventRowView(
                                event: event,
                                isOverlapping: calendarService.isOverlapping(event),
                                overlappingEvents: calendarService.getOverlappingEvents(for: event),
                                bufferWarning: calendarService.getBufferWarning(for: event),
                                onEdit: { editingEvent = event },
                                onDelete: { deleteEvent(event) }
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
                                overlappingEvents: calendarService.getOverlappingEvents(for: event),
                                bufferWarning: calendarService.getBufferWarning(for: event),
                                onEdit: { editingEvent = event },
                                onDelete: { deleteEvent(event) }
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

// MARK: - Buffer Warning Banner
struct BufferWarningBanner: View {
    let warningCount: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.badge.exclamationmark")
                .foregroundStyle(.purple)

            Text("\(warningCount) back-to-back \(warningCount == 1 ? "meeting" : "meetings") - no buffer time")
                .font(.caption)
                .fontWeight(.medium)

            Spacer()
        }
        .padding(10)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Event Row View
struct EventRowView: View {
    let event: CalendarEvent
    var isOverlapping: Bool = false
    var overlappingEvents: [CalendarEvent] = []
    var bufferWarning: BufferWarning? = nil
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    @State private var showOverlapDetails = false
    @State private var showBufferDetails = false
    @State private var showDeleteConfirmation = false
    @State private var isHovering = false

    private var hasBufferWarning: Bool {
        bufferWarning != nil
    }

    private var hasAnyWarning: Bool {
        isOverlapping || hasBufferWarning
    }

    private var borderColor: Color {
        if isOverlapping { return .orange }
        if hasBufferWarning { return .purple }
        return .clear
    }

    private var backgroundColor: Color {
        if isOverlapping { return Color.orange.opacity(0.05) }
        if hasBufferWarning { return Color.purple.opacity(0.05) }
        return Color.primary.opacity(0.03)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Calendar color indicator with warning badges
                ZStack(alignment: .top) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(hex: event.calendarColorHex) ?? .blue)
                        .frame(width: 4)

                    if isOverlapping {
                        Circle()
                            .fill(.orange)
                            .frame(width: 8, height: 8)
                            .offset(x: 0, y: -2)
                    } else if hasBufferWarning {
                        Circle()
                            .fill(.purple)
                            .frame(width: 8, height: 8)
                            .offset(x: 0, y: -2)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Title row with warning indicators
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

                        if hasBufferWarning {
                            Button {
                                showBufferDetails.toggle()
                            } label: {
                                Image(systemName: "clock.badge.exclamationmark")
                                    .font(.caption)
                                    .foregroundStyle(.purple)
                            }
                            .buttonStyle(.plain)
                            .help("No buffer time")
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

                // Action buttons (visible on hover)
                if isHovering {
                    HStack(spacing: 4) {
                        if let onEdit = onEdit {
                            Button {
                                onEdit()
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                            .help("Edit event")
                        }

                        if onDelete != nil {
                            Button {
                                showDeleteConfirmation = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.red.opacity(0.8))
                            .help("Delete event")
                        }
                    }
                    .padding(.leading, 4)
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

            // Buffer warning details expandable section
            if showBufferDetails, let warning = bufferWarning {
                VStack(alignment: .leading, spacing: 6) {
                    Divider()

                    HStack(spacing: 6) {
                        Image(systemName: warning.isBackToBack ? "bolt.fill" : "timer")
                            .font(.caption)
                            .foregroundStyle(.purple)

                        Text(warning.warningMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)

                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: warning.nextEvent.calendarColorHex) ?? .blue)
                            .frame(width: 3, height: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(warning.nextEvent.title)
                                .font(.caption)
                                .fontWeight(.medium)
                                .lineLimit(1)

                            Text(warning.nextEvent.timeRange)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 10)
                }
                .padding(.bottom, 10)
                .background(Color.purple.opacity(0.05))
            }
        }
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor.opacity(0.3), lineWidth: hasAnyWarning ? 1 : 0)
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            if let onEdit = onEdit {
                Button {
                    onEdit()
                } label: {
                    Label("Edit Event", systemImage: "pencil")
                }
            }

            if let meetingLink = event.meetingLink {
                Button {
                    NSWorkspace.shared.open(meetingLink.url)
                } label: {
                    Label("Join \(meetingLink.platform.rawValue)", systemImage: "video")
                }
            }

            Divider()

            if onDelete != nil {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete Event", systemImage: "trash")
                }
            }
        }
        .confirmationDialog(
            "Delete Event",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete?()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete \"\(event.title)\"? This cannot be undone.")
        }
    }
}

#Preview {
    CalendarView()
        .frame(width: 400, height: 400)
}
