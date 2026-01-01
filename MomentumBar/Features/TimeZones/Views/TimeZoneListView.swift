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

            addButton
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

    private var addButton: some View {
        Button {
            showingAddSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Time Zone")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.blue)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// MARK: - Edit Time Zone View
struct EditTimeZoneView: View {
    let entry: TimeZoneEntry
    @Binding var isPresented: Bool
    @State private var appState = AppState.shared
    @State private var customName: String = ""
    @State private var selectedColor: Color = .blue

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Time Zone")
                .font(.headline)

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

            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ColorPicker("Select color", selection: $selectedColor)
                    .labelsHidden()
            }

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
        .frame(width: 300)
        .onAppear {
            customName = entry.customName ?? ""
            selectedColor = entry.color
        }
    }

    private func saveChanges() {
        var updatedEntry = entry
        updatedEntry.customName = customName.isEmpty ? nil : customName
        updatedEntry.colorHex = selectedColor.toHex()
        appState.updateTimeZone(updatedEntry)
        isPresented = false
    }
}

#Preview {
    TimeZoneListView()
        .frame(width: 400, height: 400)
}
