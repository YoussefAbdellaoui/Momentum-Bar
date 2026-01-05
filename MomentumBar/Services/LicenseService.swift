//
//  LicenseService.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation
import SwiftUI

/// Main orchestrator for license management
/// Handles trial, activation, validation, and status tracking
@MainActor
@Observable
final class LicenseService {

    // MARK: - Singleton
    static let shared = LicenseService()

    // MARK: - Dependencies
    private let keychain = KeychainLicenseManager.shared
    private let api = LicenseAPIClient.shared
    private let hardwareID = HardwareIDGenerator.shared

    // MARK: - Observable State
    var currentStatus: LicenseStatus = .expired
    var currentLicense: License?
    var trialInfo: TrialInfo?
    var isLoading: Bool = false
    var lastError: String?

    // MARK: - Computed Properties

    var isLicensed: Bool {
        if case .licensed = currentStatus { return true }
        return false
    }

    var isInTrial: Bool {
        if case .trial = currentStatus { return true }
        return false
    }

    var canUseApp: Bool {
        currentStatus.isValid
    }

    var hardwareIdentifier: String {
        hardwareID.generateHardwareID()
    }

    var machineName: String {
        hardwareID.getMachineName()
    }

    // MARK: - Initialization

    private init() {
        // Load initial state synchronously
        loadInitialState()
    }

    private func loadInitialState() {
        // Try to load existing license
        if let license = try? keychain.retrieveLicense() {
            currentLicense = license
            // Check if hardware matches
            if license.isMachineAuthorized(hardwareID: hardwareIdentifier) {
                currentStatus = .licensed(tier: license.tier)
            } else {
                currentStatus = .invalid(reason: "License not activated on this machine")
            }
        } else if let trial = try? keychain.retrieveTrialInfo() {
            trialInfo = trial
            if trial.isExpired {
                currentStatus = .expired
            } else {
                currentStatus = .trial(daysRemaining: trial.daysRemaining)
            }
        } else {
            // First launch - no license, no trial
            currentStatus = .expired
        }
    }

    // MARK: - Launch Validation

    /// Call this at app launch to validate license status
    func validateAtLaunch() async {
        isLoading = true
        lastError = nil

        defer { isLoading = false }

        // 1. Check for existing license
        if let license = try? keychain.retrieveLicense() {
            currentLicense = license

            // Check hardware ID
            guard license.isMachineAuthorized(hardwareID: hardwareIdentifier) else {
                currentStatus = .invalid(reason: "License not activated on this machine")
                return
            }

            // Check cache validity
            if license.isCacheValid {
                currentStatus = .licensed(tier: license.tier)

                // Phone home in background if network available (non-blocking)
                if api.isNetworkAvailable {
                    Task {
                        await phoneHome(license: license)
                    }
                }
                return
            }

            // Cache expired - need to revalidate
            if api.isNetworkAvailable {
                let result = await validateWithServer(license: license)
                if result {
                    currentStatus = .licensed(tier: license.tier)
                } else {
                    // Server validation failed but we had a valid license
                    // Give grace period
                    currentStatus = .licensed(tier: license.tier)
                    lastError = "Unable to verify license. Please connect to internet."
                }
            } else {
                // Offline and cache expired
                currentStatus = .invalid(reason: "License validation required. Please connect to internet.")
            }
            return
        }

        // 2. No license - check trial
        if let trial = try? keychain.retrieveTrialInfo() {
            trialInfo = trial
            if trial.isExpired {
                currentStatus = .expired
            } else {
                currentStatus = .trial(daysRemaining: trial.daysRemaining)
            }
            return
        }

        // 3. First launch - start trial
        startTrial()
    }

    // MARK: - Trial Management

    /// Start a new trial period
    func startTrial() {
        let trial = TrialInfo(startDate: Date(), durationDays: 3)
        trialInfo = trial

        do {
            try keychain.storeTrialStart(trial.startDate)
            currentStatus = .trial(daysRemaining: trial.daysRemaining)
        } catch {
            lastError = "Failed to start trial: \(error.localizedDescription)"
            currentStatus = .expired
        }
    }

    /// Check and update trial status
    func refreshTrialStatus() {
        guard let trial = trialInfo else {
            if let storedTrial = try? keychain.retrieveTrialInfo() {
                trialInfo = storedTrial
                if storedTrial.isExpired {
                    currentStatus = .expired
                } else {
                    currentStatus = .trial(daysRemaining: storedTrial.daysRemaining)
                }
            }
            return
        }

        if trial.isExpired {
            currentStatus = .expired
        } else {
            currentStatus = .trial(daysRemaining: trial.daysRemaining)
        }
    }

    // MARK: - License Activation

    /// Activate a license key
    func activateLicense(key: String) async -> ActivationResult {
        isLoading = true
        lastError = nil

        defer { isLoading = false }

        // Validate key format
        guard key.isValidLicenseKeyFormat else {
            let message = "Invalid license key format. Expected: XXXX-XXXXX-XXXXX-XXXXX"
            lastError = message
            return .invalidKey(message: message)
        }

        // Check network
        guard api.isNetworkAvailable else {
            let message = "No internet connection. Please connect to activate."
            lastError = message
            return .networkError(message: message)
        }

        do {
            // Call API
            let license = try await api.activateLicense(
                key: key,
                hardwareID: hardwareIdentifier,
                machineName: machineName
            )

            // Store license
            try keychain.storeLicense(license)

            // Update state
            currentLicense = license
            currentStatus = .licensed(tier: license.tier)

            // Clear trial info
            try? keychain.deleteTrialInfo()
            trialInfo = nil

            return .success(license: license)
        } catch let error as LicenseAPIClient.APIError {
            lastError = error.localizedDescription

            switch error {
            case .machineLimitReached:
                return .limitReached(message: error.localizedDescription)
            case .machineAlreadyActivated:
                // Try to retrieve existing license
                if let license = try? keychain.retrieveLicense() {
                    return .alreadyActivated(license: license)
                }
                return .invalidKey(message: error.localizedDescription)
            default:
                return .invalidKey(message: error.localizedDescription)
            }
        } catch {
            lastError = error.localizedDescription
            return .networkError(message: error.localizedDescription)
        }
    }

    // MARK: - License Deactivation

    /// Deactivate license from this machine
    func deactivateLicense() async -> Bool {
        guard let license = currentLicense else { return false }

        isLoading = true
        lastError = nil

        defer { isLoading = false }

        // Try to deactivate on server
        if api.isNetworkAvailable {
            do {
                _ = try await api.deactivateMachine(
                    key: license.licenseKey,
                    hardwareID: hardwareIdentifier
                )
            } catch {
                // Log but continue - we'll clear local data anyway
                print("Failed to deactivate on server: \(error)")
            }
        }

        // Clear local data
        do {
            try keychain.deleteLicense()
            currentLicense = nil
            currentStatus = .expired

            // Don't restart trial - they had a license
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    // MARK: - Server Validation

    /// Validate license with server and update cache
    private func validateWithServer(license: License) async -> Bool {
        do {
            let result = try await api.validateLicense(
                key: license.licenseKey,
                hardwareID: hardwareIdentifier
            )

            switch result {
            case .valid(let updatedLicense):
                // Update stored license with fresh data
                try keychain.storeLicense(updatedLicense)
                currentLicense = updatedLicense
                return true

            case .invalid(let reason):
                lastError = reason
                return false

            case .networkError:
                // Network error during validation - keep existing license
                return license.isCacheValid

            default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    /// Phone home to server (non-blocking background check)
    private func phoneHome(license: License) async {
        _ = await validateWithServer(license: license)
    }

    // MARK: - Utility Methods

    /// Force refresh license status
    func refresh() async {
        await validateAtLaunch()
    }

    /// Clear all license data (for testing/debugging)
    func clearAllData() {
        try? keychain.clearAll()
        currentLicense = nil
        trialInfo = nil
        currentStatus = .expired
        lastError = nil
    }
}

// MARK: - License Status Display Helpers
extension LicenseService {
    var statusColor: Color {
        switch currentStatus {
        case .licensed:
            return .green
        case .trial:
            return .orange
        case .expired, .invalid:
            return .red
        }
    }

    var statusIcon: String {
        switch currentStatus {
        case .licensed:
            return "checkmark.seal.fill"
        case .trial:
            return "clock.fill"
        case .expired:
            return "exclamationmark.triangle.fill"
        case .invalid:
            return "xmark.seal.fill"
        }
    }
}
