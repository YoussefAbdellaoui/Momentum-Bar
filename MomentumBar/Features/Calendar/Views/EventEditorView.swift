//
//  EventEditorView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI
import EventKit
internal import UniformTypeIdentifiers

// MARK: - Event Editor Mode
enum EventEditorMode {
    case create
    case edit(CalendarEvent)

    var title: String {
        switch self {
        case .create: return "New Event"
        case .edit: return "Edit Event"
        }
    }
}

// MARK: - Event Editor View
struct EventEditorView: View {
    let mode: EventEditorMode
    @Binding var isPresented: Bool

    @StateObject private var calendarService = CalendarService.shared

    // Form fields
    @State private var title: String = ""
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date().addingTimeInterval(3600)
    @State private var isAllDay: Bool = false
    @State private var selectedCalendarID: String = ""
    @State private var location: String = ""
    @State private var notes: String = ""
    @State private var urlString: String = ""

    // State
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isSaving: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
                .padding()
                .background(Color.primary.opacity(0.03))

            Divider()

            // Form
            ScrollView {
                VStack(spacing: 16) {
                    titleSection
                    dateTimeSection
                    calendarSection
                    locationSection
                    notesSection
                    urlSection
                }
                .padding()
            }

            Divider()

            // Footer
            footer
                .padding()
        }
        .frame(width: 420, height: 520)
        .onAppear(perform: loadExistingEvent)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Text(mode.title)
                .font(.headline)

            Spacer()

            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Title")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("Event title", text: $title)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Date/Time Section
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("All-day event", isOn: $isAllDay)
                .toggleStyle(.switch)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Start")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if isAllDay {
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                    } else {
                        DatePicker("", selection: $startDate)
                            .labelsHidden()
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("End")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if isAllDay {
                        DatePicker("", selection: $endDate, displayedComponents: .date)
                            .labelsHidden()
                    } else {
                        DatePicker("", selection: $endDate)
                            .labelsHidden()
                    }
                }
            }

            // Duration indicator
            if !isAllDay {
                let duration = endDate.timeIntervalSince(startDate)
                if duration > 0 {
                    Text("Duration: \(formatDuration(duration))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("End time must be after start time")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .onChange(of: startDate) { _, newValue in
            // Keep end date at least 30 min after start
            if endDate <= newValue {
                endDate = newValue.addingTimeInterval(1800)
            }
        }
    }

    // MARK: - Calendar Section
    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Calendar")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("", selection: $selectedCalendarID) {
                ForEach(calendarService.writableCalendars, id: \.calendarIdentifier) { calendar in
                    HStack {
                        Circle()
                            .fill(Color(cgColor: calendar.cgColor ?? CGColor(red: 0, green: 0.5, blue: 1, alpha: 1)))
                            .frame(width: 10, height: 10)
                        Text(calendar.title)
                    }
                    .tag(calendar.calendarIdentifier)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
        }
    }

    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Location")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("Add location or video call link", text: $location)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $notes)
                .font(.body)
                .frame(height: 80)
                .padding(4)
                .background(Color.primary.opacity(0.03))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                )
        }
    }

    // MARK: - URL Section
    private var urlSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("URL")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("https://", text: $urlString)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Footer
    private var footer: some View {
        HStack {
            if case .edit(let event) = mode {
                Button(role: .destructive) {
                    deleteEvent(event)
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Button("Cancel") {
                isPresented = false
            }
            .keyboardShortcut(.cancelAction)

            Button(isSaving ? "Saving..." : "Save") {
                saveEvent()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(title.isEmpty || isSaving || endDate <= startDate)
        }
    }

    // MARK: - Actions

    private func loadExistingEvent() {
        // Set default calendar
        if let defaultCal = calendarService.defaultCalendar {
            selectedCalendarID = defaultCal.calendarIdentifier
        }

        // Load existing event data if editing
        if case .edit(let event) = mode {
            title = event.title
            startDate = event.startDate
            endDate = event.endDate
            isAllDay = event.isAllDay
            location = event.location ?? ""
            notes = event.notes ?? ""
            urlString = event.url?.absoluteString ?? ""

            // Try to find the calendar
            if let cal = calendarService.availableCalendars.first(where: { $0.title == event.calendarTitle }) {
                selectedCalendarID = cal.calendarIdentifier
            }
        }
    }

    private func saveEvent() {
        isSaving = true

        let calendar = calendarService.writableCalendars.first { $0.calendarIdentifier == selectedCalendarID }
        let url = urlString.isEmpty ? nil : URL(string: urlString)

        do {
            switch mode {
            case .create:
                _ = try calendarService.createEvent(
                    title: title,
                    startDate: startDate,
                    endDate: endDate,
                    isAllDay: isAllDay,
                    calendar: calendar,
                    notes: notes.isEmpty ? nil : notes,
                    location: location.isEmpty ? nil : location,
                    url: url
                )

            case .edit(let event):
                try calendarService.updateEvent(
                    event,
                    title: title,
                    startDate: startDate,
                    endDate: endDate,
                    isAllDay: isAllDay,
                    notes: notes,
                    location: location,
                    url: url
                )
            }

            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isSaving = false
    }

    private func deleteEvent(_ event: CalendarEvent) {
        do {
            try calendarService.deleteEvent(event)
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        } else {
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
}

// MARK: - Quick Event Creator (Compact)
struct QuickEventCreator: View {
    @Binding var isPresented: Bool
    @StateObject private var calendarService = CalendarService.shared

    @State private var title: String = ""
    @State private var startDate: Date = Date()
    @State private var duration: Int = 60 // minutes
    @State private var selectedCalendarID: String = ""
    @State private var isSaving: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    private let durations = [15, 30, 45, 60, 90, 120]

    var body: some View {
        VStack(spacing: 12) {
            // Title
            TextField("Event title", text: $title)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 12) {
                // Start time
                DatePicker("", selection: $startDate)
                    .labelsHidden()

                // Duration
                Picker("", selection: $duration) {
                    ForEach(durations, id: \.self) { mins in
                        Text(formatDurationOption(mins)).tag(mins)
                    }
                }
                .labelsHidden()
                .frame(width: 80)
            }

            // Calendar picker
            Picker("", selection: $selectedCalendarID) {
                ForEach(calendarService.writableCalendars, id: \.calendarIdentifier) { calendar in
                    HStack {
                        Circle()
                            .fill(Color(cgColor: calendar.cgColor ?? CGColor(red: 0, green: 0.5, blue: 1, alpha: 1)))
                            .frame(width: 8, height: 8)
                        Text(calendar.title)
                    }
                    .tag(calendar.calendarIdentifier)
                }
            }
            .labelsHidden()

            // Actions
            HStack {
                Button("Cancel") {
                    isPresented = false
                }

                Spacer()

                Button("Create") {
                    createEvent()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.isEmpty || isSaving)
            }
        }
        .padding()
        .frame(width: 320)
        .onAppear {
            if let defaultCal = calendarService.defaultCalendar {
                selectedCalendarID = defaultCal.calendarIdentifier
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func createEvent() {
        isSaving = true

        let calendar = calendarService.writableCalendars.first { $0.calendarIdentifier == selectedCalendarID }
        let endDate = startDate.addingTimeInterval(Double(duration * 60))

        do {
            _ = try calendarService.createEvent(
                title: title,
                startDate: startDate,
                endDate: endDate,
                calendar: calendar
            )
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }

        isSaving = false
    }

    private func formatDurationOption(_ minutes: Int) -> String {
        if minutes >= 60 {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins > 0 {
                return "\(hours)h \(mins)m"
            }
            return "\(hours)h"
        }
        return "\(minutes)m"
    }
}

// MARK: - ICS Import/Export View
struct ICSManagerView: View {
    @Binding var isPresented: Bool
    @StateObject private var calendarService = CalendarService.shared

    @State private var selectedCalendarID: String = ""
    @State private var importResult: String = ""
    @State private var showImportResult: Bool = false
    @State private var isExporting: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Import / Export")
                    .font(.headline)
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color.primary.opacity(0.03))

            Divider()

            VStack(spacing: 20) {
                // Import Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Import Events", systemImage: "square.and.arrow.down")
                        .font(.headline)

                    Text("Import events from an .ics file into your calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Picker("Import to:", selection: $selectedCalendarID) {
                            ForEach(calendarService.writableCalendars, id: \.calendarIdentifier) { calendar in
                                Text(calendar.title).tag(calendar.calendarIdentifier)
                            }
                        }
                        .labelsHidden()

                        Button("Choose File...") {
                            importICSFile()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color.primary.opacity(0.03))
                .cornerRadius(8)

                // Export Section
                VStack(alignment: .leading, spacing: 12) {
                    Label("Export Events", systemImage: "square.and.arrow.up")
                        .font(.headline)

                    Text("Export your upcoming events to an .ics file that can be imported into any calendar app")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("\(calendarService.upcomingEvents.count) events available")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button("Export...") {
                            exportICSFile()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(calendarService.upcomingEvents.isEmpty)
                    }
                }
                .padding()
                .background(Color.primary.opacity(0.03))
                .cornerRadius(8)

                Spacer()
            }
            .padding()
        }
        .frame(width: 400, height: 340)
        .onAppear {
            if let defaultCal = calendarService.defaultCalendar {
                selectedCalendarID = defaultCal.calendarIdentifier
            }
        }
        .alert("Import Complete", isPresented: $showImportResult) {
            Button("OK") { }
        } message: {
            Text(importResult)
        }
    }

    private func importICSFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "ics")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            guard let calendar = calendarService.writableCalendars.first(where: { $0.calendarIdentifier == selectedCalendarID }) else {
                importResult = "No calendar selected"
                showImportResult = true
                return
            }

            do {
                let count = try calendarService.importFromICS(url: url, to: calendar)
                importResult = "Successfully imported \(count) event\(count == 1 ? "" : "s")"
            } catch {
                importResult = "Import failed: \(error.localizedDescription)"
            }
            showImportResult = true
        }
    }

    private func exportICSFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "ics")!]
        panel.nameFieldStringValue = "MomentumBar-Events.ics"

        if panel.runModal() == .OK, let url = panel.url {
            let icsContent = calendarService.exportToICS(events: calendarService.upcomingEvents)

            do {
                try icsContent.write(to: url, atomically: true, encoding: .utf8)
                NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
            } catch {
                print("Export failed: \(error)")
            }
        }
    }
}

#Preview("Event Editor") {
    EventEditorView(mode: .create, isPresented: .constant(true))
}

#Preview("Quick Creator") {
    QuickEventCreator(isPresented: .constant(true))
}
