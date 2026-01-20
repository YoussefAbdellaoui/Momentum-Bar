//
//  LicenseAPIClient.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation
import Network

/// Handles communication with the license server for activation and validation
final class LicenseAPIClient {

    // MARK: - Singleton
    static let shared = LicenseAPIClient()
    private init() {
        startNetworkMonitoringIfNeeded()
    }

    // MARK: - Configuration

    /// Base URL for the license API
    private let baseURL = "https://momentum-bar-production.up.railway.app/api/v1"

    /// Request timeout in seconds
    private let timeout: TimeInterval = 30

    /// Custom URLSession with proper configuration
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        config.allowsExpensiveNetworkAccess = true
        config.allowsConstrainedNetworkAccess = true
        return URLSession(configuration: config)
    }()

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
        let hardwareId: String
        let machineName: String
        let appVersion: String
    }

    private struct ActivationResponse: Decodable {
        let success: Bool
        let license: ServerLicenseData?
        let message: String?
        let error: String?
        let errorCode: String?
    }

    /// Response structure matching what the server actually returns
    private struct ServerLicenseData: Decodable {
        let tier: String
        let email: String
        let maxMachines: Int
        let activatedMachines: Int
        let expiresAt: String?
    }

    private struct ValidationRequest: Encodable {
        let licenseKey: String
        let hardwareId: String
    }

    private struct ValidationResponse: Decodable {
        let valid: Bool
        let message: String?
        let license: ServerLicenseData?
    }

    private struct DeactivationRequest: Encodable {
        let licenseKey: String
        let hardwareId: String
    }

    private struct DeactivationResponse: Decodable {
        let success: Bool
        let message: String?
    }

    // MARK: - Network Availability

    private let pathMonitor = NWPathMonitor()
    private let pathMonitorQueue = DispatchQueue(label: "com.momentumbar.license.network")
    private var _isNetworkAvailable: Bool = true

    /// Check if network is available (updated via NWPathMonitor)
    var isNetworkAvailable: Bool { _isNetworkAvailable }

    private func startNetworkMonitoringIfNeeded() {
        // If the path monitor has not been started, start it. NWPathMonitor ignores duplicate starts.
        pathMonitor.pathUpdateHandler = { [weak self] path in
            self?._isNetworkAvailable = (path.status == .satisfied)
        }
        pathMonitor.start(queue: pathMonitorQueue)
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
            hardwareId: hardwareID,
            machineName: machineName,
            appVersion: Bundle.main.appVersion
        )

        print("[LicenseAPI] Activating with hardware ID: \(hardwareID)")
        print("[LicenseAPI] Machine name: \(machineName)")

        let response: ActivationResponse = try await post(
            endpoint: "/license/activate",
            body: request
        )

        if response.success, let licenseData = response.license {
            return try convertToLicense(licenseData, licenseKey: key, hardwareId: hardwareID)
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
            hardwareId: hardwareID
        )

        do {
            let response: ValidationResponse = try await post(
                endpoint: "/license/validate",
                body: request
            )

            if response.valid, let licenseData = response.license {
                let license = try convertToLicense(licenseData, licenseKey: key, hardwareId: hardwareID)
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
            hardwareId: hardwareID
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
        let fullURL = baseURL + endpoint
        guard let url = URL(string: fullURL) else {
            print("[LicenseAPI] Invalid URL: \(fullURL)")
            throw APIError.invalidURL
        }

        print("[LicenseAPI] Making request to: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("MomentumBar/\(Bundle.main.appVersion)", forHTTPHeaderField: "User-Agent")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch {
            print("[LicenseAPI] Network error: \(error)")
            print("[LicenseAPI] Error domain: \((error as NSError).domain)")
            print("[LicenseAPI] Error code: \((error as NSError).code)")
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Log response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("[LicenseAPI] Response (\(httpResponse.statusCode)): \(responseString)")
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
            print("[LicenseAPI] Decoding error: \(error)")
            throw APIError.decodingError(error)
        }
    }

    private func convertToLicense(_ data: ServerLicenseData, licenseKey: String, hardwareId: String) throws -> License {
        guard let tier = LicenseTier(rawValue: data.tier) else {
            throw APIError.decodingError(NSError(domain: "License", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown tier"]))
        }

        // Create a machine entry for the current machine
        let currentMachine = MachineEntry(
            id: hardwareId,
            machineName: Host.current().localizedName ?? "This Mac",
            activatedDate: Date()
        )

        return License(
            tier: tier,
            licenseKey: licenseKey,
            email: data.email,
            purchaseDate: Date(), // Server doesn't return this, use current date
            maxMachines: data.maxMachines,
            activeMachines: [currentMachine],
            signature: "", // Server doesn't return signature
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

