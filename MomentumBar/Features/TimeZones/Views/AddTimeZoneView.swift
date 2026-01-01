//
//  AddTimeZoneView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI

struct AddTimeZoneView: View {
    @Binding var isPresented: Bool
    @State private var appState = AppState.shared
    @State private var searchText = ""
    @State private var selectedZone: TimeZoneService.TimeZoneInfo?

    private let timeZoneService = TimeZoneService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Add Time Zone")
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

            Divider()

            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search cities or time zones...", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Results list
            ScrollView {
                LazyVStack(spacing: 0) {
                    if searchText.isEmpty {
                        // Show popular time zones
                        Section {
                            ForEach(timeZoneService.popularTimeZones()) { zone in
                                TimeZoneSearchRow(zone: zone) {
                                    addTimeZone(zone)
                                }
                            }
                        } header: {
                            SectionHeader(title: "Popular")
                        }
                    } else {
                        // Show search results
                        let results = timeZoneService.searchTimeZones(query: searchText)

                        if results.isEmpty {
                            noResultsView
                        } else {
                            ForEach(results) { zone in
                                TimeZoneSearchRow(zone: zone) {
                                    addTimeZone(zone)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(width: 400, height: 500)
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)

            Text("No results found")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Try a different search term")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func addTimeZone(_ zone: TimeZoneService.TimeZoneInfo) {
        // Check if already added
        guard !appState.timeZones.contains(where: { $0.identifier == zone.identifier }) else {
            isPresented = false
            return
        }

        let entry = TimeZoneEntry(
            identifier: zone.identifier,
            customName: nil,
            order: appState.timeZones.count
        )
        appState.addTimeZone(entry)
        isPresented = false
    }
}

// MARK: - Search Row
struct TimeZoneSearchRow: View {
    let zone: TimeZoneService.TimeZoneInfo
    let onSelect: () -> Void
    @State private var appState = AppState.shared

    private var isAlreadyAdded: Bool {
        appState.timeZones.contains { $0.identifier == zone.identifier }
    }

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(zone.displayName)
                        .font(.body)
                        .foregroundStyle(isAlreadyAdded ? .secondary : .primary)

                    HStack(spacing: 4) {
                        Text(zone.abbreviation)
                        Text("•")
                        Text(zone.offsetString)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if isAlreadyAdded {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isAlreadyAdded)

        Divider()
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.top, 8)
    }
}

#Preview {
    AddTimeZoneView(isPresented: .constant(true))
}
