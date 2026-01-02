//
//  LicenseSettingsView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI

struct LicenseSettingsView: View {
    @State private var licenseService = LicenseService.shared
    @State private var licenseKeyInput: String = ""
    @State private var showActivationAlert: Bool = false
    @State private var activationMessage: String = ""
    @State private var isActivationSuccess: Bool = false

    var body: some View {
        Form {
            // Status Section
            Section {
                LicenseStatusRow(status: licenseService.currentStatus)

                if let license = licenseService.currentLicense {
                    LabeledContent("Email") {
                        Text(license.email)
                            .foregroundStyle(.secondary)
                    }

                    LabeledContent("License Key") {
                        Text(maskedLicenseKey(license.licenseKey))
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    if license.isCacheValid {
                        LabeledContent("Offline Valid Until") {
                            Text(license.cacheValidUntil, style: .date)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if licenseService.isInTrial, let trial = licenseService.trialInfo {
                    TrialCountdownRow(trial: trial)
                }
            } header: {
                Text("License Status")
            }

            // Machine Slots Section (if licensed)
            if let license = licenseService.currentLicense {
                Section {
                    MachineSlotsList(
                        license: license,
                        currentMachineID: licenseService.hardwareIdentifier
                    )
                } header: {
                    Text("Machine Slots (\(license.usedSlots)/\(license.maxMachines) used)")
                }

                Section {
                    Button(role: .destructive) {
                        Task {
                            await deactivateLicense()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Deactivate This Machine")
                        }
                    }
                    .disabled(licenseService.isLoading)
                }
            }

            // Activation Section
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enter a license key to activate:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        TextField("XXXX-XXXXX-XXXXX-XXXXX", text: $licenseKeyInput)
                            .font(.system(.body, design: .monospaced))
                            .textFieldStyle(.roundedBorder)
                            .textCase(.uppercase)
                            .onChange(of: licenseKeyInput) { _, newValue in
                                licenseKeyInput = formatLicenseKey(newValue)
                            }

                        Button("Activate") {
                            Task {
                                await activateLicense()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(licenseKeyInput.isEmpty || licenseService.isLoading)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Activate License")
            }

            // Purchase Section
            Section {
                PurchaseOptionsView()
            } header: {
                Text("Purchase")
            }

            // Error Display
            if let error = licenseService.lastError {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .disabled(licenseService.isLoading)
        .overlay {
            if licenseService.isLoading {
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
        .alert(activationMessage, isPresented: $showActivationAlert) {
            Button("OK") { }
        }
    }

    // MARK: - Actions

    private func activateLicense() async {
        let result = await licenseService.activateLicense(key: licenseKeyInput)

        switch result {
        case .success:
            activationMessage = "License activated successfully!"
            isActivationSuccess = true
            licenseKeyInput = ""
        case .alreadyActivated:
            activationMessage = "License is already activated on this machine."
            isActivationSuccess = true
        case .invalidKey(let message):
            activationMessage = message
            isActivationSuccess = false
        case .limitReached(let message):
            activationMessage = message
            isActivationSuccess = false
        case .networkError(let message):
            activationMessage = message
            isActivationSuccess = false
        }

        showActivationAlert = true
    }

    private func deactivateLicense() async {
        let success = await licenseService.deactivateLicense()
        if success {
            activationMessage = "License deactivated from this machine."
        } else {
            activationMessage = "Failed to deactivate license."
        }
        showActivationAlert = true
    }

    // MARK: - Helpers

    private func maskedLicenseKey(_ key: String) -> String {
        // Show first 4 chars, mask middle, show last 5
        guard key.count > 10 else { return key }
        let prefix = String(key.prefix(4))
        let suffix = String(key.suffix(5))
        return "\(prefix)-XXXXX-XXXXX-\(suffix)"
    }

    private func formatLicenseKey(_ input: String) -> String {
        // Remove non-alphanumeric except hyphens
        let cleaned = input.uppercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }

        // Auto-format with hyphens
        var result = ""
        var charCount = 0

        for char in cleaned {
            if char == "-" {
                continue // Skip existing hyphens, we'll add them
            }

            result.append(char)
            charCount += 1

            // Add hyphen after positions 4, 9, 14
            if charCount == 4 || charCount == 9 || charCount == 14 {
                if charCount < 19 { // Don't add after last group
                    result.append("-")
                }
            }
        }

        // Limit total length
        return String(result.prefix(24)) // XXXX-XXXXX-XXXXX-XXXXX = 24 chars
    }
}

// MARK: - License Status Row
struct LicenseStatusRow: View {
    let status: LicenseStatus

    var body: some View {
        HStack {
            Image(systemName: statusIcon)
                .foregroundStyle(statusColor)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("Status")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(status.displayName)
                    .font(.headline)
                    .foregroundStyle(statusColor)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch status {
        case .licensed: return .green
        case .trial: return .orange
        case .expired, .invalid: return .red
        }
    }

    private var statusIcon: String {
        switch status {
        case .licensed: return "checkmark.seal.fill"
        case .trial: return "clock.fill"
        case .expired: return "exclamationmark.triangle.fill"
        case .invalid: return "xmark.seal.fill"
        }
    }
}

// MARK: - Trial Countdown Row
struct TrialCountdownRow: View {
    let trial: TrialInfo

    var body: some View {
        HStack {
            Image(systemName: "hourglass")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Trial Period")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if trial.daysRemaining > 0 {
                    Text("\(trial.daysRemaining) day\(trial.daysRemaining == 1 ? "" : "s") remaining")
                        .font(.headline)
                } else {
                    Text("\(trial.hoursRemaining) hours remaining")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
            }

            Spacer()

            Text("Expires: \(trial.expirationDate, style: .date)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Machine Slots List
struct MachineSlotsList: View {
    let license: License
    let currentMachineID: String

    var body: some View {
        ForEach(license.activeMachines) { machine in
            HStack {
                Image(systemName: machine.id == currentMachineID ? "desktopcomputer" : "laptopcomputer")
                    .foregroundStyle(machine.id == currentMachineID ? .blue : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(machine.machineName)
                            .font(.subheadline)

                        if machine.id == currentMachineID {
                            Text("(This Mac)")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }

                    Text("Activated: \(machine.activatedDate, style: .date)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
            }
            .padding(.vertical, 2)
        }

        // Empty slots
        if license.availableSlots > 0 {
            ForEach(0..<license.availableSlots, id: \.self) { _ in
                HStack {
                    Image(systemName: "plus.circle.dashed")
                        .foregroundStyle(.secondary)

                    Text("Available slot")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(.vertical, 2)
            }
        }
    }
}

// MARK: - Purchase Options
struct PurchaseOptionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(LicenseTier.allCases, id: \.self) { tier in
                PurchaseTierRow(tier: tier)
            }

            Divider()

            Link(destination: URL(string: "https://momentumbar.app/purchase")!) {
                HStack {
                    Text("Visit our website to purchase")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                }
            }
            .buttonStyle(.plain)
        }
    }
}

struct PurchaseTierRow: View {
    let tier: LicenseTier

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(tier.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(tier.price)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }

                Text(tier.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(tier.maxMachines) Mac\(tier.maxMachines > 1 ? "s" : "")")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
        }
    }
}

// MARK: - Preview
#Preview {
    LicenseSettingsView()
        .frame(width: 500, height: 600)
}
