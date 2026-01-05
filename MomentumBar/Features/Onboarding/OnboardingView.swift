//
//  OnboardingView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI
import EventKit

struct OnboardingView: View {
    @State private var onboardingService = OnboardingService.shared
    @State private var calendarService = CalendarService.shared
    @State private var focusService = FocusModeService.shared
    @State private var showFocusSetup = false

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<onboardingService.totalSteps, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index <= onboardingService.currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)

            // Skip button
            HStack {
                Spacer()
                if !onboardingService.isLastStep {
                    Button("Skip") {
                        onboardingService.skipOnboarding()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.caption)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Spacer()

            // Step content
            stepContent

            Spacer()

            // Navigation buttons
            HStack(spacing: 16) {
                if !onboardingService.isFirstStep {
                    Button {
                        withAnimation {
                            onboardingService.previousStep()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button {
                    withAnimation {
                        onboardingService.nextStep()
                    }
                } label: {
                    HStack {
                        Text(onboardingService.isLastStep ? "Get Started" : "Continue")
                        if !onboardingService.isLastStep {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .frame(width: 480, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .sheet(isPresented: $showFocusSetup) {
            FocusModeSetupSheet(isPresented: $showFocusSetup)
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        let step = onboardingService.currentOnboardingStep

        VStack(spacing: 20) {
            // Icon
            Image(systemName: step.iconName)
                .font(.system(size: 64))
                .foregroundStyle(Color(hex: step.iconColor) ?? .accentColor)

            // Title
            Text(step.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Subtitle
            Text(step.subtitle)
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Description
            Text(step.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .padding(.horizontal, 40)

            // Optional action button
            if step.hasAction {
                actionButton(for: step)
                    .padding(.top, 8)
            }

            // Status indicator for action steps
            if step == .calendar {
                calendarStatusIndicator
            } else if step == .focusMode {
                focusStatusIndicator
            }
        }
    }

    @ViewBuilder
    private func actionButton(for step: OnboardingStep) -> some View {
        switch step {
        case .calendar:
            if calendarService.authorizationStatus != .fullAccess {
                Button(step.actionTitle ?? "Setup") {
                    Task {
                        await calendarService.requestAccess()
                    }
                }
                .buttonStyle(.bordered)
            }

        case .focusMode:
            if !focusService.isSetupComplete {
                Button(step.actionTitle ?? "Setup") {
                    showFocusSetup = true
                }
                .buttonStyle(.bordered)
            }

        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var calendarStatusIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: calendarService.authorizationStatus == .fullAccess ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(calendarService.authorizationStatus == .fullAccess ? .green : .secondary)

            Text(calendarService.authorizationStatus == .fullAccess ? "Calendar connected" : "Calendar access not granted")
                .font(.caption)
                .foregroundStyle(calendarService.authorizationStatus == .fullAccess ? .primary : .secondary)
        }
    }

    @ViewBuilder
    private var focusStatusIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: focusService.isSetupComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(focusService.isSetupComplete ? .green : .secondary)

            Text(focusService.isSetupComplete ? "Focus Mode configured" : "Focus Mode not configured")
                .font(.caption)
                .foregroundStyle(focusService.isSetupComplete ? .primary : .secondary)
        }
    }
}

// MARK: - Onboarding Window Controller
@MainActor
final class OnboardingWindowController {
    static let shared = OnboardingWindowController()

    private var window: NSWindow?
    private var onboardingService = OnboardingService.shared

    private init() {}

    func showOnboardingIfNeeded() {
        guard onboardingService.shouldShowOnboarding else { return }
        showOnboarding()
    }

    func showOnboarding() {
        if window != nil {
            window?.makeKeyAndOrderFront(nil)
            return
        }

        let contentView = OnboardingView()

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "Welcome to MomentumBar"
        newWindow.contentView = NSHostingView(rootView: contentView)
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = WindowDelegateHandler.shared

        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeOnboarding() {
        window?.close()
        window = nil
    }
}

// MARK: - Window Delegate Handler
private class WindowDelegateHandler: NSObject, NSWindowDelegate {
    static let shared = WindowDelegateHandler()

    func windowWillClose(_ notification: Notification) {
        // Mark onboarding as complete when window is closed (e.g., user clicks X)
        Task { @MainActor in
            // Only complete if not already completed (prevents redundant calls)
            if !OnboardingService.shared.hasCompletedOnboarding {
                OnboardingService.shared.completeOnboarding()
            }
            OnboardingWindowController.shared.closeOnboarding()
        }
    }
}

#Preview {
    OnboardingView()
}
