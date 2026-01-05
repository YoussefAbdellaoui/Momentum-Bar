//
//  TimezoneCardView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI
import AppKit

// MARK: - Shareable Timezone Card
struct TimezoneCardView: View {
    let timeZones: [TimeZoneEntry]
    let currentTime: Date
    let preferences: AppPreferences

    @State private var themeManager = ThemeManager.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

            Divider()
                .padding(.horizontal, 20)

            // Timezone list
            VStack(spacing: 12) {
                ForEach(timeZones) { entry in
                    timezoneRow(entry)
                }
            }
            .padding(20)

            // Footer
            footerView
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
        }
        .background(
            LinearGradient(
                colors: [
                    Color(NSColor.windowBackgroundColor),
                    Color(NSColor.windowBackgroundColor).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("World Clock")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Awake/Asleep count
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "sun.max.fill")
                        .foregroundStyle(themeManager.currentTheme.daytimeColor)
                    Text("\(awakeCount)")
                        .fontWeight(.medium)
                }

                HStack(spacing: 4) {
                    Image(systemName: "moon.fill")
                        .foregroundStyle(themeManager.currentTheme.nighttimeColor)
                    Text("\(asleepCount)")
                        .fontWeight(.medium)
                }
            }
            .font(.caption)
        }
    }

    private func timezoneRow(_ entry: TimeZoneEntry) -> some View {
        HStack(spacing: 12) {
            // Day/Night indicator
            ZStack {
                Circle()
                    .fill(isDaytime(for: entry) ?
                          themeManager.currentTheme.daytimeColor.opacity(0.2) :
                          themeManager.currentTheme.nighttimeColor.opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: isDaytime(for: entry) ? "sun.max.fill" : "moon.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(isDaytime(for: entry) ?
                                     themeManager.currentTheme.daytimeColor :
                                     themeManager.currentTheme.nighttimeColor)
            }

            // Location info
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayName)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 4) {
                    Text(entry.abbreviation)
                    Text("•")
                    Text(entry.currentOffset)
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Time
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedTime(for: entry))
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)

                if showDate(for: entry) {
                    Text(formattedDateShort(for: entry))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(10)
    }

    private var footerView: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.caption2)
                Text("MomentumBar")
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.secondary)

            Spacer()

            Text("momentumbar.app")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: currentTime)
    }

    private var awakeCount: Int {
        timeZones.filter { isDaytime(for: $0) }.count
    }

    private var asleepCount: Int {
        timeZones.count - awakeCount
    }

    private func isDaytime(for entry: TimeZoneEntry) -> Bool {
        guard let tz = entry.timeZone else { return true }
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: tz, from: currentTime)
        let hour = components.hour ?? 12
        return hour >= 6 && hour < 18
    }

    private func formattedTime(for entry: TimeZoneEntry) -> String {
        guard let tz = entry.timeZone else { return "--:--" }
        let formatter = DateFormatter()
        formatter.timeZone = tz

        if preferences.use24HourFormat {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "h:mm a"
        }

        return formatter.string(from: currentTime)
    }

    private func formattedDateShort(for entry: TimeZoneEntry) -> String {
        guard let tz = entry.timeZone else { return "" }
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: currentTime)
    }

    private func showDate(for entry: TimeZoneEntry) -> Bool {
        guard let tz = entry.timeZone else { return false }
        let localFormatter = DateFormatter()
        localFormatter.timeZone = TimeZone.current
        localFormatter.dateFormat = "yyyy-MM-dd"

        let zoneFormatter = DateFormatter()
        zoneFormatter.timeZone = tz
        zoneFormatter.dateFormat = "yyyy-MM-dd"

        return localFormatter.string(from: currentTime) != zoneFormatter.string(from: currentTime)
    }
}

// MARK: - Card Image Renderer
@MainActor
struct TimezoneCardRenderer {

    static func renderToImage(timeZones: [TimeZoneEntry], currentTime: Date, preferences: AppPreferences) -> NSImage? {
        let cardView = TimezoneCardView(
            timeZones: timeZones,
            currentTime: currentTime,
            preferences: preferences
        )

        // Calculate dynamic height based on number of timezones
        let baseHeight: CGFloat = 140 // Header + footer
        let rowHeight: CGFloat = 64 // Each timezone row
        let totalHeight = baseHeight + (CGFloat(timeZones.count) * rowHeight)
        let width: CGFloat = 380

        let renderer = ImageRenderer(content: cardView.frame(width: width, height: totalHeight))
        renderer.scale = 2.0 // Retina

        guard let cgImage = renderer.cgImage else { return nil }

        return NSImage(cgImage: cgImage, size: NSSize(width: width, height: totalHeight))
    }

    static func copyToClipboard(timeZones: [TimeZoneEntry], currentTime: Date, preferences: AppPreferences) -> Bool {
        guard let image = renderToImage(timeZones: timeZones, currentTime: currentTime, preferences: preferences) else {
            return false
        }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        return true
    }

    static func saveToFile(timeZones: [TimeZoneEntry], currentTime: Date, preferences: AppPreferences) -> URL? {
        guard let image = renderToImage(timeZones: timeZones, currentTime: currentTime, preferences: preferences) else {
            return nil
        }

        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }

        let fileName = "MomentumBar-WorldClock-\(formattedTimestamp()).png"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try pngData.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to save timezone card: \(error)")
            return nil
        }
    }

    private static func formattedTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: Date())
    }
}

// MARK: - Share Sheet Presenter
@MainActor
struct ShareSheetPresenter {

    static func present(timeZones: [TimeZoneEntry], currentTime: Date, preferences: AppPreferences, from view: NSView) {
        guard let image = TimezoneCardRenderer.renderToImage(
            timeZones: timeZones,
            currentTime: currentTime,
            preferences: preferences
        ) else { return }

        // Also create a temp file for services that prefer files
        let tempURL = TimezoneCardRenderer.saveToFile(
            timeZones: timeZones,
            currentTime: currentTime,
            preferences: preferences
        )

        var items: [Any] = [image]
        if let url = tempURL {
            items.append(url)
        }

        let picker = NSSharingServicePicker(items: items)
        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }
}

// MARK: - Share Button View
struct ShareTimezoneCardButton: View {
    @State private var appState = AppState.shared
    @State private var showCopiedFeedback = false

    var body: some View {
        Menu {
            Button {
                shareCard()
            } label: {
                Label("Share...", systemImage: "square.and.arrow.up")
            }

            Button {
                copyToClipboard()
            } label: {
                Label("Copy to Clipboard", systemImage: "doc.on.doc")
            }

            Divider()

            Button {
                saveToDesktop()
            } label: {
                Label("Save to Desktop", systemImage: "arrow.down.doc")
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: showCopiedFeedback ? "checkmark" : "square.and.arrow.up")
                Text(showCopiedFeedback ? "Copied!" : "Share")
            }
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.1))
            .foregroundStyle(Color.accentColor)
            .cornerRadius(6)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private func shareCard() {
        // Get the current window's content view for positioning
        guard let window = NSApp.keyWindow,
              let contentView = window.contentView else { return }

        ShareSheetPresenter.present(
            timeZones: appState.timeZones,
            currentTime: appState.currentTime,
            preferences: appState.preferences,
            from: contentView
        )
    }

    private func copyToClipboard() {
        let success = TimezoneCardRenderer.copyToClipboard(
            timeZones: appState.timeZones,
            currentTime: appState.currentTime,
            preferences: appState.preferences
        )

        if success {
            withAnimation {
                showCopiedFeedback = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showCopiedFeedback = false
                }
            }
        }
    }

    private func saveToDesktop() {
        guard let image = TimezoneCardRenderer.renderToImage(
            timeZones: appState.timeZones,
            currentTime: appState.currentTime,
            preferences: appState.preferences
        ) else { return }

        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else { return }

        let fileName = "MomentumBar-WorldClock.png"
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let fileURL = desktopURL.appendingPathComponent(fileName)

        do {
            try pngData.write(to: fileURL)
            NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: "")
        } catch {
            print("Failed to save to desktop: \(error)")
        }
    }
}

#Preview {
    TimezoneCardView(
        timeZones: [
            TimeZoneEntry(identifier: "America/New_York", customName: "New York"),
            TimeZoneEntry(identifier: "Europe/London", customName: "London"),
            TimeZoneEntry(identifier: "Asia/Tokyo", customName: "Tokyo"),
            TimeZoneEntry(identifier: "Australia/Sydney", customName: "Sydney")
        ],
        currentTime: Date(),
        preferences: .default
    )
    .frame(width: 380)
    .padding(40)
    .background(Color.gray.opacity(0.2))
}
