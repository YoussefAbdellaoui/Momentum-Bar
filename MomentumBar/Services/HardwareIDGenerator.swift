//
//  HardwareIDGenerator.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation
import IOKit
import CryptoKit

/// Generates a unique, stable hardware identifier for this Mac
/// Combines: Serial Number + Primary MAC Address + Model Identifier
/// The resulting ID survives OS reinstalls and is unique per machine
final class HardwareIDGenerator {

    // MARK: - Singleton
    static let shared = HardwareIDGenerator()
    private init() {}

    // MARK: - Cached Hardware ID
    private var cachedHardwareID: String?

    /// Generate a stable, unique hardware identifier
    /// Returns a SHA256 hash of combined hardware attributes
    func generateHardwareID() -> String {
        if let cached = cachedHardwareID {
            return cached
        }

        let serial = getSerialNumber() ?? "UNKNOWN_SERIAL"
        let macAddress = getPrimaryMACAddress() ?? "00:00:00:00:00:00"
        let model = getModelIdentifier() ?? "Unknown_Model"

        // Combine all identifiers
        let combined = "\(serial)-\(macAddress)-\(model)"

        // Hash with SHA256 for consistent length and privacy
        let hardwareID = sha256Hash(combined)
        cachedHardwareID = hardwareID

        return hardwareID
    }

    /// Get a human-readable machine name for display
    func getMachineName() -> String {
        // Try to get the computer name
        if let computerName = Host.current().localizedName {
            return computerName
        }

        // Fallback to model identifier
        return getModelIdentifier() ?? "Mac"
    }

    // MARK: - Serial Number (via IOKit)

    private func getSerialNumber() -> String? {
        let platformExpert = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice")
        )

        guard platformExpert != 0 else { return nil }

        defer { IOObjectRelease(platformExpert) }

        guard let serialNumberCF = IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformSerialNumberKey as CFString,
            kCFAllocatorDefault,
            0
        ) else {
            return nil
        }

        return serialNumberCF.takeRetainedValue() as? String
    }

    // MARK: - MAC Address (Primary Network Interface)

    private func getPrimaryMACAddress() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return nil
        }

        defer { freeifaddrs(ifaddr) }

        // Look for en0 (typically Wi-Fi) or en1 (Ethernet)
        let preferredInterfaces = ["en0", "en1"]

        for interfaceName in preferredInterfaces {
            var current = firstAddr
            while true {
                let interface = current.pointee
                let name = String(cString: interface.ifa_name)

                if name == interfaceName {
                    let family = interface.ifa_addr.pointee.sa_family
                    if family == UInt8(AF_LINK) {
                        // Found the link-layer address
                        if let macAddress = extractMACAddress(from: interface.ifa_addr) {
                            return macAddress
                        }
                    }
                }

                guard let next = interface.ifa_next else { break }
                current = next
            }
        }

        return nil
    }

    private func extractMACAddress(from sockaddr: UnsafeMutablePointer<sockaddr>) -> String? {
        let data = sockaddr.withMemoryRebound(to: sockaddr_dl.self, capacity: 1) { sdl -> Data in
            let length = Int(sdl.pointee.sdl_alen)
            let dataPointer = withUnsafePointer(to: &sdl.pointee.sdl_data) { ptr in
                return ptr.withMemoryRebound(to: UInt8.self, capacity: length) { uint8Ptr in
                    return uint8Ptr.advanced(by: Int(sdl.pointee.sdl_nlen))
                }
            }
            return Data(bytes: dataPointer, count: length)
        }

        guard data.count == 6 else { return nil }

        return data.map { String(format: "%02x", $0) }.joined(separator: ":")
    }

    // MARK: - Model Identifier

    private func getModelIdentifier() -> String? {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)

        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)

        return String(cString: model)
    }

    // MARK: - SHA256 Hashing

    private func sha256Hash(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Debug/Testing Support

#if DEBUG
extension HardwareIDGenerator {
    /// Returns the raw components (for debugging only)
    func debugComponents() -> (serial: String?, mac: String?, model: String?) {
        return (
            serial: getSerialNumber(),
            mac: getPrimaryMACAddress(),
            model: getModelIdentifier()
        )
    }
}
#endif
