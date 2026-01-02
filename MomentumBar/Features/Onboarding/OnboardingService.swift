//
//  OnboardingService.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation

@MainActor
@Observable
final class OnboardingService {
    static let shared = OnboardingService()

    private(set) var hasCompletedOnboarding: Bool = false
    private(set) var currentStep: Int = 0

    private let storageKey = "com.momentumbar.onboardingCompleted"
    private let versionKey = "com.momentumbar.onboardingVersion"
    private let currentOnboardingVersion = 1

    private init() {
        loadState()
    }

    var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding
    }

    var totalSteps: Int {
        OnboardingStep.allCases.count
    }

    var currentOnboardingStep: OnboardingStep {
        OnboardingStep.allCases[safe: currentStep] ?? .welcome
    }

    var isLastStep: Bool {
        currentStep >= totalSteps - 1
    }

    var isFirstStep: Bool {
        currentStep == 0
    }

    // MARK: - Navigation

    func nextStep() {
        guard currentStep < totalSteps - 1 else {
            completeOnboarding()
            return
        }
        currentStep += 1
    }

    func previousStep() {
        guard currentStep > 0 else { return }
        currentStep -= 1
    }

    func skipOnboarding() {
        completeOnboarding()
    }

    func goToStep(_ step: Int) {
        guard step >= 0 && step < totalSteps else { return }
        currentStep = step
    }

    // MARK: - Completion

    func completeOnboarding() {
        hasCompletedOnboarding = true
        saveState()
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentStep = 0
        saveState()
    }

    // MARK: - Persistence

    private func loadState() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: storageKey)

        // Check if onboarding version has changed (for future updates)
        let savedVersion = UserDefaults.standard.integer(forKey: versionKey)
        if savedVersion < currentOnboardingVersion && hasCompletedOnboarding {
            // Reset onboarding for new version features
            // Uncomment below to force re-onboarding on version change
            // hasCompletedOnboarding = false
        }
    }

    private func saveState() {
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: storageKey)
        UserDefaults.standard.set(currentOnboardingVersion, forKey: versionKey)
    }
}

// MARK: - Onboarding Steps
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case timeZones
    case calendar
    case pomodoro
    case focusMode
    case getStarted

    var title: String {
        switch self {
        case .welcome: return "Welcome to MomentumBar"
        case .timeZones: return "World Time Zones"
        case .calendar: return "Calendar Integration"
        case .pomodoro: return "Pomodoro Timer"
        case .focusMode: return "Focus Mode"
        case .getStarted: return "You're All Set!"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome:
            return "Your productivity companion in the menu bar"
        case .timeZones:
            return "Keep track of time across the globe"
        case .calendar:
            return "Never miss a meeting again"
        case .pomodoro:
            return "Stay focused with timed work sessions"
        case .focusMode:
            return "Minimize distractions automatically"
        case .getStarted:
            return "Start your productive journey"
        }
    }

    var description: String {
        switch self {
        case .welcome:
            return "MomentumBar helps you manage time zones, calendar events, and focus sessions—all from your menu bar."
        case .timeZones:
            return "Add time zones for your team members, clients, or favorite cities. See day/night indicators at a glance and convert times easily."
        case .calendar:
            return "Connect your calendar to see upcoming meetings, get reminders before they start, and join with one click."
        case .pomodoro:
            return "Use the Pomodoro technique to work in focused 25-minute sessions with short breaks. Track your daily focus time."
        case .focusMode:
            return "Automatically enable macOS Focus mode during Pomodoro sessions or meetings to minimize distractions."
        case .getStarted:
            return "Click the menu bar icon anytime to access all features. Customize everything in Settings."
        }
    }

    var iconName: String {
        switch self {
        case .welcome: return "clock.fill"
        case .timeZones: return "globe"
        case .calendar: return "calendar"
        case .pomodoro: return "timer"
        case .focusMode: return "moon.fill"
        case .getStarted: return "checkmark.circle.fill"
        }
    }

    var iconColor: String {
        switch self {
        case .welcome: return "#007AFF"
        case .timeZones: return "#34C759"
        case .calendar: return "#FF9500"
        case .pomodoro: return "#FF3B30"
        case .focusMode: return "#AF52DE"
        case .getStarted: return "#34C759"
        }
    }

    var hasAction: Bool {
        switch self {
        case .calendar, .focusMode: return true
        default: return false
        }
    }

    var actionTitle: String? {
        switch self {
        case .calendar: return "Grant Calendar Access"
        case .focusMode: return "Setup Focus Mode"
        default: return nil
        }
    }
}

// MARK: - Collection Safe Subscript
extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
