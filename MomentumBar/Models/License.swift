//
//  License.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation

// MARK: - License Tier
enum LicenseTier: String, Codable, CaseIterable {
    case solo = "solo"
    case multiple = "multiple"
    case enterprise = "enterprise"

    var displayName: String {
        switch self {
        case .solo: return "Solo"
        case .multiple: return "Multiple"
        case .enterprise: return "Enterprise"
        }
    }

    var maxMachines: Int {
        switch self {
        case .solo: return 1
        case .multiple: return 3
        case .enterprise: return 1 // Per seat
        }
    }

    var price: String {
        switch self {
        case .solo: return "$14.99"
        case .multiple: return "$24.99"
        case .enterprise: return "$64.99+"
        }
    }

    var description: String {
        switch self {
        case .solo: return "1 Mac, perfect for individual use"
        case .multiple: return "Up to 3 Macs, for multi-device users"
        case .enterprise: return "Team licensing with seat management"
        }
    }

    /// Validates if a license key matches this tier
    var keyPrefix: String {
        switch self {
        case .solo: return "SOLO-"
        case .multiple: return "MULTI-"
        case .enterprise: return "TEAM-"
        }
    }
}

// MARK: - License Status
enum LicenseStatus: Equatable {
    case trial(daysRemaining: Int)
    case licensed(tier: LicenseTier)
    case expired
    case invalid(reason: String)

    var isValid: Bool {
        switch self {
        case .trial, .licensed:
            return true
        case .expired, .invalid:
            return false
        }
    }

    var displayName: String {
        switch self {
        case .trial(let days):
            return "Trial (\(days) day\(days == 1 ? "" : "s") left)"
        case .licensed(let tier):
            return "Licensed (\(tier.displayName))"
        case .expired:
            return "Trial Expired"
        case .invalid(let reason):
            return "Invalid: \(reason)"
        }
    }
}

// MARK: - Trial Info
struct TrialInfo: Codable, Equatable {
    let startDate: Date
    let durationDays: Int

    init(startDate: Date = Date(), durationDays: Int = 3) {
        self.startDate = startDate
        self.durationDays = durationDays
    }

    var expirationDate: Date {
        Calendar.current.date(byAdding: .day, value: durationDays, to: startDate) ?? startDate
    }

    var isExpired: Bool {
        Date() > expirationDate
    }

    var daysRemaining: Int {
        let components = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate)
        return max(0, (components.day ?? 0) + 1) // +1 because we count the current day
    }

    var hoursRemaining: Int {
        let components = Calendar.current.dateComponents([.hour], from: Date(), to: expirationDate)
        return max(0, components.hour ?? 0)
    }
}

// MARK: - Machine Entry
struct MachineEntry: Codable, Identifiable, Equatable {
    let id: String // Hardware ID
    let machineName: String
    let activatedDate: Date
    var reactivationsUsed: Int
    let reactivationsLimit: Int
    var lastReactivationDate: Date?

    init(
        id: String,
        machineName: String,
        activatedDate: Date = Date(),
        reactivationsUsed: Int = 0,
        reactivationsLimit: Int = 1,
        lastReactivationDate: Date? = nil
    ) {
        self.id = id
        self.machineName = machineName
        self.activatedDate = activatedDate
        self.reactivationsUsed = reactivationsUsed
        self.reactivationsLimit = reactivationsLimit
        self.lastReactivationDate = lastReactivationDate
    }

    var canReactivate: Bool {
        guard reactivationsUsed < reactivationsLimit else { return false }

        // Check if 12 months have passed since last reactivation
        if let lastDate = lastReactivationDate {
            let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
            return lastDate < oneYearAgo
        }

        return true
    }
}

// MARK: - License (Main Model)
struct License: Codable, Equatable {
    let tier: LicenseTier
    let licenseKey: String
    let email: String
    let purchaseDate: Date
    let maxMachines: Int
    var activeMachines: [MachineEntry]
    let signature: String // RSA-2048 signature (base64)

    // Cache validity
    var lastValidated: Date
    var cacheValidUntil: Date

    init(
        tier: LicenseTier,
        licenseKey: String,
        email: String,
        purchaseDate: Date = Date(),
        maxMachines: Int? = nil,
        activeMachines: [MachineEntry] = [],
        signature: String = "",
        lastValidated: Date = Date(),
        cacheValidUntil: Date? = nil
    ) {
        self.tier = tier
        self.licenseKey = licenseKey
        self.email = email
        self.purchaseDate = purchaseDate
        self.maxMachines = maxMachines ?? tier.maxMachines
        self.activeMachines = activeMachines
        self.signature = signature
        self.lastValidated = lastValidated
        self.cacheValidUntil = cacheValidUntil ?? Calendar.current.date(byAdding: .day, value: 30, to: Date())!
    }

    var isCacheValid: Bool {
        Date() < cacheValidUntil
    }

    var availableSlots: Int {
        maxMachines - activeMachines.count
    }

    var usedSlots: Int {
        activeMachines.count
    }

    func isMachineAuthorized(hardwareID: String) -> Bool {
        activeMachines.contains { $0.id == hardwareID }
    }

    func machineEntry(for hardwareID: String) -> MachineEntry? {
        activeMachines.first { $0.id == hardwareID }
    }
}

// MARK: - Enterprise License Extensions
struct EnterpriseSeat: Codable, Identifiable, Equatable {
    let id: String // Seat ID (e.g., "SEAT_001")
    let seatLicenseKey: String // SEAT-XXXXX-XXXXX-XXXXX
    let userEmail: String
    var activeMachines: [MachineEntry]
    var activated: Bool
    var activatedDate: Date?

    init(
        id: String,
        seatLicenseKey: String,
        userEmail: String,
        activeMachines: [MachineEntry] = [],
        activated: Bool = false,
        activatedDate: Date? = nil
    ) {
        self.id = id
        self.seatLicenseKey = seatLicenseKey
        self.userEmail = userEmail
        self.activeMachines = activeMachines
        self.activated = activated
        self.activatedDate = activatedDate
    }
}

struct EnterpriseLicense: Codable, Equatable {
    let teamLicenseKey: String // TEAM-XXXXX-XXXXX-XXXXX
    let organization: String
    let teamLeadEmail: String
    let purchaseDate: Date
    let maxSeats: Int
    var activatedSeats: [EnterpriseSeat]
    let billingEmail: String
    let signature: String

    var unusedSeats: Int {
        maxSeats - activatedSeats.count
    }
}

// MARK: - Validation Result
enum ValidationResult: Equatable {
    case valid(license: License)
    case invalid(reason: String)
    case hardwareMismatch(message: String)
    case expired(message: String)
    case limitReached(message: String)
    case networkError(message: String)
    case noLicense

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }

    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let reason):
            return reason
        case .hardwareMismatch(let message):
            return message
        case .expired(let message):
            return message
        case .limitReached(let message):
            return message
        case .networkError(let message):
            return message
        case .noLicense:
            return "No license found"
        }
    }
}

// MARK: - Activation Result
enum ActivationResult: Equatable {
    case success(license: License)
    case alreadyActivated(license: License)
    case invalidKey(message: String)
    case limitReached(message: String)
    case networkError(message: String)

    var isSuccess: Bool {
        switch self {
        case .success, .alreadyActivated:
            return true
        default:
            return false
        }
    }

    var license: License? {
        switch self {
        case .success(let license), .alreadyActivated(let license):
            return license
        default:
            return nil
        }
    }

    var errorMessage: String? {
        switch self {
        case .success, .alreadyActivated:
            return nil
        case .invalidKey(let message):
            return message
        case .limitReached(let message):
            return message
        case .networkError(let message):
            return message
        }
    }
}

// MARK: - License Key Validation
extension String {
    /// Validates the format of a license key
    var isValidLicenseKeyFormat: Bool {
        // Format: XXXX-XXXXX-XXXXX-XXXXX (prefix + 3 groups of 5)
        let pattern = "^(SOLO|MULTI|TEAM|SEAT)-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}$"
        return range(of: pattern, options: .regularExpression) != nil
    }

    var licenseTierFromKey: LicenseTier? {
        if hasPrefix("SOLO-") { return .solo }
        if hasPrefix("MULTI-") { return .multiple }
        if hasPrefix("TEAM-") { return .enterprise }
        return nil
    }

    var isSeatKey: Bool {
        hasPrefix("SEAT-")
    }
}
