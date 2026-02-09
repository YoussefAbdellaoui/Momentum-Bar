//
//  AnnouncementListView.swift
//  MomentumBar
//
//  Created by Codex on behalf of Youssef Abdellaoui.
//

import SwiftUI

struct AnnouncementListView: View {
    @State private var service = AnnouncementService.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    let onClose: (() -> Void)?
    @State private var onboardingService = OnboardingService.shared

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            content
        }
        .frame(minWidth: 420, minHeight: 360)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            refresh()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Announcements")
                    .font(.headline)
                Text("Latest updates and news")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isLoading {
                ProgressView()
                    .controlSize(.small)
            }

            if onboardingService.hasCompletedOnboarding && service.unreadCount > 0 {
                Button("Mark all read") {
                    service.markAllSeen()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            if let onClose {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain)
                .help("Close")
            }

            Button {
                refresh(force: true)
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .help("Refresh")
        }
        .padding()
    }

    private var content: some View {
        VStack(spacing: 0) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }

            if !onboardingService.hasCompletedOnboarding {
                VStack(spacing: 8) {
                    Text("Announcements available after onboarding")
                        .foregroundStyle(.secondary)
                    Text("Finish onboarding to start receiving updates and news.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if service.announcements.isEmpty {
                VStack(spacing: 8) {
                    Text("No announcements yet.")
                        .foregroundStyle(.secondary)
                    Text("We’ll show updates here as soon as they’re available.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(service.announcements) { announcement in
                            AnnouncementRow(
                                announcement: announcement,
                                isRead: service.isAnnouncementSeen(announcement),
                                onMarkRead: {
                                    service.markAnnouncementSeen(announcement)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }

    private func refresh(force: Bool = false) {
        guard onboardingService.hasCompletedOnboarding else { return }
        isLoading = true
        errorMessage = nil
        Task { @MainActor in
            _ = await service.refreshAnnouncements(force: force)
            isLoading = false
        }
    }
}

private struct AnnouncementRow: View {
    let announcement: Announcement
    let isRead: Bool
    let onMarkRead: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(announcement.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(announcement.type.displayName)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(announcement.type.badgeColor.opacity(0.2))
                    .foregroundStyle(announcement.type.badgeColor)
                    .clipShape(Capsule())
            }

            Text(announcement.body)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                if let url = announcement.linkURL {
                    Button("Open link") {
                        NSWorkspace.shared.open(url)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                if isRead {
                    Text("Read")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    Button("Mark read") {
                        onMarkRead()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isRead ? 0.55 : 1)
    }
}

private extension Announcement.AnnouncementType {
    var displayName: String {
        switch self {
        case .info:
            return "Info"
        case .warning:
            return "Warning"
        case .critical:
            return "Critical"
        }
    }

    var badgeColor: Color {
        switch self {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .critical:
            return .red
        }
    }
}
