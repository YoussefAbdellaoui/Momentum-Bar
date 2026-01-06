//
//  LicenseAPIClient.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation

/// Handles communication with the license server for activation and validation
final class LicenseAPIClient {

    // MARK: - Singleton
    static let shared = LicenseAPIClient()
    private init() {}

    // MARK: - Configuration

    /// Base URL for the license API
    /// TODO: Replace with your actual license server URL
    private let baseURL = "https://momentum-bar-production.up.railway.app/api/v1"

    /// Request timeout in seconds
    private let timeout: TimeInterval = 30

    // MARK: - Errors
    enum APIError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case serverError(statusCode: Int, message: String?)
        case decodingError(Error)
        case invalidLicenseKey
        case licenseNotFound
        case machineAlreadyActivated
        case machineLimitReached
        case licenseRevoked

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid server URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid response from server"
            case .serverError(let code, let message):
                return message ?? "Server error (code: \(code))"
            case .decodingError:
                return "Failed to process server response"
            case .invalidLicenseKey:
                return "Invalid license key format"
            case .licenseNotFound:
                return "License key not found"
            case .machineAlreadyActivated:
                return "This license is already activated on this machine"
            case .machineLimitReached:
                return "Maximum number of machines reached for this license"
            case .licenseRevoked:
                return "This license has been revoked"
            }
        }
    }

    // MARK: - API Response Models

    private struct ActivationRequest: Encodable {
        let licenseKey: String
        let hardwareID: String
        let machineName: String
        let appVersion: String
    }

    private struct ActivationResponse: Decodable {
        let success: Bool
        let license: LicenseData?
        let error: String?
        let errorCode: String?
    }

    private struct LicenseData: Decodable {
        let tier: String
        let licenseKey: String
        let email: String
        let purchaseDate: String
        let maxMachines: Int
        let activeMachines: [MachineData]
        let signature: String
    }

    private struct MachineData: Decodable {
        let id: String
        let machineName: String
        let activatedDate: String
    }

    private struct ValidationRequest: Encodable {
        let licenseKey: String
        let hardwareID: String
    }

    private struct ValidationResponse: Decodable {
        let valid: Bool
        let message: String?
        let license: LicenseData?
    }

    private struct DeactivationRequest: Encodable {
        let licenseKey: String
        let hardwareID: String
    }

    private struct DeactivationResponse: Decodable {
        let success: Bool
        let message: String?
    }

    // MARK: - Network Availability

    /// Check if network is available
    var isNetworkAvailable: Bool {
        // Simple reachability check
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }

        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)

        return isReachable && !needsConnection
    }

    // MARK: - API Methods

    /// Activate a license key on this machine
    func activateLicense(
        key: String,
        hardwareID: String,
        machineName: String
    ) async throws -> License {
        // Validate key format first
        guard key.isValidLicenseKeyFormat else {
            throw APIError.invalidLicenseKey
        }

        let request = ActivationRequest(
            licenseKey: key,
            hardwareID: hardwareID,
            machineName: machineName,
            appVersion: Bundle.main.appVersion
        )

        let response: ActivationResponse = try await post(
            endpoint: "/license/activate",
            body: request
        )

        if response.success, let licenseData = response.license {
            return try convertToLicense(licenseData)
        } else {
            // Map error codes to specific errors
            if let errorCode = response.errorCode {
                switch errorCode {
                case "INVALID_KEY":
                    throw APIError.licenseNotFound
                case "ALREADY_ACTIVATED":
                    throw APIError.machineAlreadyActivated
                case "LIMIT_REACHED":
                    throw APIError.machineLimitReached
                case "REVOKED":
                    throw APIError.licenseRevoked
                default:
                    throw APIError.serverError(statusCode: 400, message: response.error)
                }
            }
            throw APIError.serverError(statusCode: 400, message: response.error)
        }
    }

    /// Validate an existing license
    func validateLicense(
        key: String,
        hardwareID: String
    ) async throws -> ValidationResult {
        let request = ValidationRequest(
            licenseKey: key,
            hardwareID: hardwareID
        )

        do {
            let response: ValidationResponse = try await post(
                endpoint: "/license/validate",
                body: request
            )

            if response.valid, let licenseData = response.license {
                let license = try convertToLicense(licenseData)
                return .valid(license: license)
            } else {
                return .invalid(reason: response.message ?? "License validation failed")
            }
        } catch let error as APIError {
            switch error {
            case .networkError:
                return .networkError(message: error.localizedDescription)
            default:
                return .invalid(reason: error.localizedDescription)
            }
        }
    }

    /// Deactivate this machine from a license
    func deactivateMachine(
        key: String,
        hardwareID: String
    ) async throws -> Bool {
        let request = DeactivationRequest(
            licenseKey: key,
            hardwareID: hardwareID
        )

        let response: DeactivationResponse = try await post(
            endpoint: "/license/deactivate",
            body: request
        )

        return response.success
    }

    // MARK: - Private Helpers

    private func post<T: Encodable, R: Decodable>(
        endpoint: String,
        body: T
    ) async throws -> R {
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("MomentumBar/\(Bundle.main.appVersion)", forHTTPHeaderField: "User-Agent")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to decode error message
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)["error"]
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(R.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func convertToLicense(_ data: LicenseData) throws -> License {
        guard let tier = LicenseTier(rawValue: data.tier) else {
            throw APIError.decodingError(NSError(domain: "License", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown tier"]))
        }

        let dateFormatter = ISO8601DateFormatter()

        let purchaseDate = dateFormatter.date(from: data.purchaseDate) ?? Date()

        let machines = data.activeMachines.map { machine in
            MachineEntry(
                id: machine.id,
                machineName: machine.machineName,
                activatedDate: dateFormatter.date(from: machine.activatedDate) ?? Date()
            )
        }

        return License(
            tier: tier,
            licenseKey: data.licenseKey,
            email: data.email,
            purchaseDate: purchaseDate,
            maxMachines: data.maxMachines,
            activeMachines: machines,
            signature: data.signature,
            lastValidated: Date(),
            cacheValidUntil: Calendar.current.date(byAdding: .day, value: 30, to: Date())
        )
    }
}

// MARK: - Bundle Extension
private extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

// MARK: - SystemConfiguration Import
import SystemConfiguration
