//
//  TrialExpiredView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI

/// Modal view shown when the trial period has expired
struct TrialExpiredView: View {
    @State private var licenseService = LicenseService.shared
    @State private var licenseKeyInput: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "clock.badge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)

                    Text("Trial Period Ended")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Your 3-day free trial has expired. Purchase a license to continue using MomentumBar.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Divider()

                // Pricing Options
                VStack(spacing: 16) {
                    Text("Choose Your Plan")
                        .font(.headline)

                    ForEach(LicenseTier.allCases, id: \.self) { tier in
                        PricingCard(tier: tier)
                    }
                }

                Divider()

                // License Key Entry
                VStack(alignment: .leading, spacing: 8) {
                    Text("Already have a license key?")
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

                    if showError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                // Footer
                HStack {
                    Link("Purchase License", destination: URL(string: "https://momentumbar.app/purchase")!)
                        .buttonStyle(.borderedProminent)

                    Spacer()

                    Button("Quit App") {
                        NSApplication.shared.terminate(nil)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(24)
        }
        .frame(width: 450, height: 600)
        .overlay {
            if licenseService.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Actions

    private func activateLicense() async {
        showError = false

        let result = await licenseService.activateLicense(key: licenseKeyInput)

        switch result {
        case .success, .alreadyActivated:
            // Close the trial expired window on successful activation
            AppDelegate.shared?.closeTrialExpiredWindow()
        case .invalidKey(let message):
            errorMessage = message
            showError = true
        case .limitReached(let message):
            errorMessage = message
            showError = true
        case .networkError(let message):
            errorMessage = message
            showError = true
        }
    }

    // MARK: - Helpers

    private func formatLicenseKey(_ input: String) -> String {
        let cleaned = input.uppercased().filter { $0.isLetter || $0.isNumber || $0 == "-" }
        var result = ""
        var charCount = 0

        for char in cleaned {
            if char == "-" { continue }
            result.append(char)
            charCount += 1
            if charCount == 4 || charCount == 9 || charCount == 14 {
                if charCount < 19 {
                    result.append("-")
                }
            }
        }

        return String(result.prefix(24))
    }
}

// MARK: - Pricing Card
struct PricingCard: View {
    let tier: LicenseTier

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(tier.displayName)
                        .font(.headline)

                    if tier == .solo {
                        Text("Popular")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .foregroundStyle(.white)
                            .cornerRadius(4)
                    }
                }

                Text(tier.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(tier.price)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)

                Text("one-time")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.primary.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(tier == .solo ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Trial Warning Banner
/// A banner to show when trial is about to expire
struct TrialWarningBanner: View {
    let daysRemaining: Int
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("Trial Ending Soon")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(daysRemaining) day\(daysRemaining == 1 ? "" : "s") remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Link("Purchase Now", destination: URL(string: "https://momentumbar.app/purchase")!)
                .font(.caption)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

            if let onDismiss = onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview
#Preview("Trial Expired") {
    TrialExpiredView()
}

#Preview("Warning Banner") {
    TrialWarningBanner(daysRemaining: 1)
        .padding()
}
