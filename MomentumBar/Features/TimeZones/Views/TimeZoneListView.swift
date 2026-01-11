//
//  TimeZoneListView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI

struct TimeZoneListView: View {
    @State private var appState = AppState.shared
    @State private var showingAddSheet = false
    @State private var editingEntry: TimeZoneEntry?

    var body: some View {
        VStack(spacing: 0) {
            if appState.timeZones.isEmpty {
                emptyStateView
            } else {
                timeZonesList
            }

            // Bottom bar with Add and Share buttons
            bottomBar
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTimeZoneView(isPresented: $showingAddSheet)
        }
        .sheet(item: $editingEntry) { entry in
            EditTimeZoneView(entry: entry, isPresented: .init(
                get: { editingEntry != nil },
                set: { if !$0 { editingEntry = nil } }
            ))
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "globe")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Time Zones")
                .font(.title3)
                .fontWeight(.medium)

            Text("Add time zones to track multiple locations")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var timeZonesList: some View {
        List {
            ForEach(appState.timeZones) { entry in
                TimeZoneRowView(entry: entry)
                    .contentShape(Rectangle())
                    .contextMenu {
                        Button("Edit") {
                            editingEntry = entry
                        }

                        Divider()

                        Button {
                            appState.togglePinToMenuBar(for: entry)
                        } label: {
                            if entry.isPinnedToMenuBar {
                                Label("Unpin from Menu Bar", systemImage: "pin.slash")
                            } else {
                                Label("Pin to Menu Bar", systemImage: "pin")
                            }
                        }
                        .disabled(!entry.isPinnedToMenuBar && !appState.canPinMoreTimeZones)

                        Divider()

                        Button("Delete", role: .destructive) {
                            if let index = appState.timeZones.firstIndex(where: { $0.id == entry.id }) {
                                appState.removeTimeZone(at: IndexSet(integer: index))
                            }
                        }
                    }
            }
            .onDelete(perform: appState.removeTimeZone)
            .onMove(perform: appState.moveTimeZone)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var bottomBar: some View {
        HStack {
            Button {
                showingAddSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Time Zone")
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.blue)

            Spacer()

            if !appState.timeZones.isEmpty {
                ShareTimezoneCardButton()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Edit Time Zone View
struct EditTimeZoneView: View {
    let entry: TimeZoneEntry
    @Binding var isPresented: Bool
    @State private var appState = AppState.shared
    @State private var customName: String = ""
    @State private var selectedColor: Color = .blue
    @State private var selectedGroupID: UUID? = nil
    @State private var teammates: [String] = []
    @State private var newTeammate: String = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Time Zone")
                .font(.headline)

            ScrollView {
                VStack(spacing: 16) {
                    // Custom Name Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom Name")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("Enter custom name", text: $customName)
                            .textFieldStyle(.roundedBorder)

                        Text("Leave empty to use default name")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    // Group Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Picker("Group", selection: $selectedGroupID) {
                            Text("No Group").tag(nil as UUID?)
                            ForEach(appState.groups) { group in
                                HStack {
                                    Image(systemName: group.icon)
                                        .foregroundStyle(group.color)
                                    Text(group.name)
                                }
                                .tag(group.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()

                        if appState.groups.isEmpty {
                            Text("Create groups in Settings → Time Zones")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    // Teammates Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Teammates")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        // List of teammates
                        if !teammates.isEmpty {
                            VStack(spacing: 4) {
                                ForEach(teammates, id: \.self) { name in
                                    HStack {
                                        Text(name)
                                            .font(.subheadline)
                                        Spacer()
                                        Button {
                                            teammates.removeAll { $0 == name }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundStyle(.secondary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color.primary.opacity(0.05))
                                    .cornerRadius(6)
                                }
                            }
                        }

                        // Add teammate field
                        HStack(spacing: 8) {
                            TextField("Add teammate", text: $newTeammate)
                                .textFieldStyle(.roundedBorder)
                                .onSubmit {
                                    addTeammate()
                                }

                            Button("Add") {
                                addTeammate()
                            }
                            .disabled(newTeammate.trimmingCharacters(in: .whitespaces).isEmpty)
                        }

                        Text("Add coworkers in this timezone")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }

                    // Color Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        ColorPicker("Select color", selection: $selectedColor)
                            .labelsHidden()
                    }
                }
            }
            .frame(maxHeight: 320)

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    saveChanges()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 320)
        .onAppear {
            customName = entry.customName ?? ""
            selectedColor = entry.color
            selectedGroupID = entry.groupID
            teammates = entry.teammates
        }
    }

    private func addTeammate() {
        let name = newTeammate.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, !teammates.contains(name) else { return }
        teammates.append(name)
        newTeammate = ""
    }

    private func saveChanges() {
        var updatedEntry = entry
        updatedEntry.customName = customName.isEmpty ? nil : customName
        updatedEntry.colorHex = selectedColor.toHex()
        updatedEntry.groupID = selectedGroupID
        updatedEntry.teammates = teammates
        appState.updateTimeZone(updatedEntry)
        isPresented = false
    }
}

#Preview {
    TimeZoneListView()
        .frame(width: 400, height: 400)
}
