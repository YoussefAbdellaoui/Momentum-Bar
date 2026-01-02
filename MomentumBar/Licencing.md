# Swift macOS App: Three-Tier Licensing System Implementation Guide
## Solo | Multiple | Enterprise Model

You are a Swift engineer implementing the licensing and anti-abuse system for a macOS time zone/calendar manager app. This document defines the exact licensing model, hardware binding, activation flows, and anti-abuse measures your app must enforce.

***

## LICENSING TIERS OVERVIEW

### Tier 1: SOLO
- **Price:** $14.99 (one-time, forever)
- **Computers:** 1 Mac allowed
- **Use Case:** Individual developers, freelancers, personal use
- **License Binding:** Tied to single machine (via hardware ID)
- **Reactivation:** 1 machine change per 12 months (e.g., new Mac purchase)
- **Offline:** Works for 30 days without internet validation
- **Support:** Standard email support

### Tier 2: MULTIPLE
- **Price:** $24.99 (one-time, forever)
- **Computers:** Up to 3 Macs allowed simultaneously
- **Use Case:** Consultants, multi-Mac users, home + work setups
- **License Binding:** Multi-machine with 3 hardware slots
- **Reactivation:** Can swap machines, 1 change per slot per 12 months
- **Offline:** Works for 30 days without internet validation
- **Support:** Standard email support

### Tier 3: ENTERPRISE
- **Price:** $64,99 for 6 seats (one-time), scales to $10.99/seat for 6-10, $9.99/seat for 11-25, custom for 26+
- **Computers:** 1 per seat (multiple seats if needed)
- **Use Case:** Organizations, remote teams, companies
- **License Binding:** Seat-based, each seat tied to 1 machine initially
- **Reactivation:** 1 machine change per seat per 12 months
- **Features:** Team admin dashboard, seat management, bulk activation, centralized billing
- **Support:** Priority email + optional phone support

***

## LICENSE KEY FORMAT & STRUCTURE

### License Key Naming Convention
- **Solo:** `SOLO-XXXXX-XXXXX-XXXXX` (32 characters alphanumeric)
- **Multiple:** `MULTI-XXXXX-XXXXX-XXXXX`
- **Enterprise:** `TEAM-XXXXX-XXXXX-XXXXX` (master) + `SEAT-XXXXX-XXXXX-XXXXX` (per-seat)

### Solo License Data Structure
```swift
struct SoloLicense: Codable {
    let tier: String = "solo"
    let licenseKey: String          // SOLO-XXXXX-XXXXX-XXXXX
    let email: String               // Purchaser email
    let hardwareID: String          // SHA256(serial + MAC + model)
    let purchaseDate: Date          // ISO 8601 format
    let maxMachines: Int = 1        // Solo = 1 only
    let activeMachines: [String]    // [hardwareID]
    let reactivationsUsed: Int      // Count of machine changes
    let reactivationsLimit: Int = 1 // Solo can change machine 1x/year
    let lastReactivationDate: Date? // When last machine change occurred
    let signature: String           // RSA-2048 signature (base64)
}
```

### Multiple License Data Structure
```swift
struct MultipleLicense: Codable {
    let tier: String = "multiple"
    let licenseKey: String
    let email: String
    let purchaseDate: Date
    let maxMachines: Int = 3        // Multiple = 3 machines max
    let activeMachines: [MachineEntry]
    let machineReactivations: [String: ReactivationTracker] // Per-machine tracking
    let signature: String
}

struct MachineEntry: Codable {
    let hardwareID: String
    let machineName: String         // "MacBook Pro 16", "iMac 27"
    let activatedDate: Date
    let reactivationsUsed: Int = 0
    let reactivationsLimit: Int = 1
    let lastReactivationDate: Date?
}
```

### Enterprise License Data Structure
```swift
struct EnterpriseLicense: Codable {
    let tier: String = "enterprise"
    let teamLicenseKey: String      // Master team key
    let organization: String        // Company name
    let teamLeadEmail: String       // Primary admin
    let purchaseDate: Date
    let maxSeats: Int               // 6, 11, 25, or custom
    let activatedSeats: [EnterpriseSeat]
    let unusedSeats: Int            // maxSeats - activatedSeats.count
    let billingEmail: String        // Invoice recipient
    let centralizedBilling: Bool = true
    let signature: String
}

struct EnterpriseSeat: Codable {
    let seatID: String              // UUID or SEAT_001
    let seatLicenseKey: String      // SEAT-XXXXX-XXXXX-XXXXX
    let userEmail: String           // alice@company.com
    let maxMachines: Int = 1        // 1 machine per seat
    let activeMachines: [MachineEntry]
    let activated: Bool
    let activatedDate: Date?
    let reactivationsUsed: Int = 0
    let reactivationsLimit: Int = 1
    let lastReactivationDate: Date?
}
```

***

## HARDWARE ID GENERATION

The hardware ID must be unique per Mac and immutable (survives OS reinstalls):

```swift
class HardwareIDGenerator {
    /// Generate stable, unique hardware identifier
    /// Combines: Serial Number + Primary MAC Address + Model Identifier
    static func generateHardwareID() -> String {
        let serial = IOPlatformSerialNumber() ?? "UNKNOWN"
        let macAddress = getPrimaryMACAddress() ?? "00:00:00:00:00:00"
        let model = getModelIdentifier() ?? "Unknown"
        
        // Combine and hash
        let combined = "\(serial)-\(macAddress)-\(model)"
        return SHA256(combined)
    }
    
    /// Get Mac serial number from IOKit
    private static func IOPlatformSerialNumber() -> String? {
        let serialNumber = IORegistryEntrySearchCFProperty(
            IOServiceMatching("IOPlatformExpertDevice"),
            kIORegistryIterateRecursively,
            "IOPlatformSerialNumber" as CFString,
            kCFAllocatorDefault
        )
        return serialNumber as? String
    }
    
    /// Get primary MAC address (en0 = Wi-Fi)
    private static func getPrimaryMACAddress() -> String? {
        // Scan network interfaces, return en0 MAC
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }
        
        for addr in sequence(first: ifaddr, next: { $0?.pointee.ifa_next }) {
            let interface = addr?.pointee
            if interface?.ifa_name == "en0" {
                // Extract MAC address from sockaddr_dl
                if let sockaddr = interface?.ifa_addr,
                   sockaddr.pointee.sa_family == AF_LINK {
                    let macBytes = extractMACBytes(sockaddr)
                    return macBytes.map { String(format: "%02x", $0) }.joined(separator: ":")
                }
            }
        }
        return nil
    }
    
    /// Get model identifier (MacBook Pro, iMac, etc.)
    private static func getModelIdentifier() -> String? {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }
}
```

***

## LICENSE STORAGE & KEYCHAIN MANAGEMENT

Store licenses securely in macOS Keychain (encrypted by OS):

```swift
class KeychainLicenseManager {
    private let serviceName = "com.yourapp.license"
    
    // MARK: - Store License
    
    func storeLicense(_ license: Codable, tier: String) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(license)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "license_\(tier)",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing
        SecItemDelete(query as CFDictionary)
        
        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }
    
    // MARK: - Retrieve License
    
    func retrieveLicense(tier: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "license_\(tier)",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw KeychainError.retrieveFailed(status)
        }
    }
    
    // MARK: - Delete License
    
    func deleteLicense(tier: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: "license_\(tier)"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}
```

***

## LICENSE VALIDATION FLOW

### At App Launch

```swift
class LicenseValidator {
    
    func validateLicenseAtLaunch() -> ValidationResult {
        // 1. Try to retrieve license from Keychain
        guard let licenseData = try? keychainManager.retrieveLicense(tier: "solo")
            ?? keychainManager.retrieveLicense(tier: "multiple")
            ?? keychainManager.retrieveLicense(tier: "enterprise") else {
            return .noLicense
        }
        
        // 2. Check cached validation (offline mode)
        if let cachedValidation = getCachedValidation() {
            if !cachedValidation.isExpired {
                return .valid(tier: cachedValidation.tier)
            }
        }
        
        // 3. Verify cryptographic signature
        guard verifyLicenseSignature(licenseData) else {
            return .invalid("License tampered or corrupted")
        }
        
        // 4. Check hardware ID
        let currentHardware = HardwareIDGenerator.generateHardwareID()
        guard isHardwareAuthorized(for: licenseData, hardwareID: currentHardware) else {
            return .hardwareMismatch("This license is tied to a different Mac")
        }
        
        // 5. Cache validation for offline use (30 days)
        cacheValidation(validUntil: Date().addingTimeInterval(30*24*3600))
        
        // 6. Phone home for optional server validation (if internet available)
        if isNetworkAvailable() {
            phoneHome(licenseData)
        }
        
        return .valid(tier: extractTierFrom(licenseData))
    }
    
    // MARK: - Signature Verification (RSA-2048)
    
    private func verifyLicenseSignature(_ licenseData: Data) -> Bool {
        do {
            let license = try JSONDecoder().decode(LicenseHeader.self, from: licenseData)
            let signatureData = Data(base64Encoded: license.signature) ?? Data()
            
            // Get embedded public key
            guard let publicKeyData = loadEmbeddedPublicKey() else { return false }
            
            // Verify signature using SecKey
            let attributes: [String: Any] = [
                kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                kSecAttrKeySizeInBits as String: 2048
            ]
            
            var error: Unmanaged<CFError>?
            guard let publicKey = SecKeyCreateWithData(
                publicKeyData as CFData,
                attributes as CFDictionary,
                &error
            ) else {
                return false
            }
            
            // Signature verification
            return SecKeyVerifySignature(
                publicKey,
                .rsaSignatureMessagePKCS1v15SHA256,
                licenseData,
                signatureData as CFData,
                &error
            )
        } catch {
            return false
        }
    }
    
    // MARK: - Hardware Authorization Check
    
    private func isHardwareAuthorized(for licenseData: Data, hardwareID: String) -> Bool {
        do {
            let decoder = JSONDecoder()
            
            // Try Solo
            if let solo = try? decoder.decode(SoloLicense.self, from: licenseData) {
                return solo.hardwareID == hardwareID
            }
            
            // Try Multiple
            if let multiple = try? decoder.decode(MultipleLicense.self, from: licenseData) {
                return multiple.activeMachines.contains(where: { $0.hardwareID == hardwareID })
            }
            
            // Try Enterprise
            if let enterprise = try? decoder.decode(EnterpriseLicense.self, from: licenseData) {
                return enterprise.activatedSeats.contains { seat in
                    seat.activeMachines.contains(where: { $0.hardwareID == hardwareID })
                }
            }
            
            return false
        } catch {
            return false
        }
    }
}

enum ValidationResult {
    case valid(tier: LicenseTier)
    case invalid(String)           // Tampered/corrupted
    case hardwareMismatch(String)   // Different Mac
    case noLicense                  // No license found
    case limitReached(String)       // Machine limit exceeded
    case offlineExpired             // Cache expired, needs internet
}

enum LicenseTier {
    case solo
    case multiple
    case enterprise
}
```

***

## TIER-SPECIFIC ACTIVATION FLOWS

### SOLO: Single-Machine Activation

```swift
class SoloActivationFlow {
    
    func activateOnNewMachine(licenseKey: String) -> ActivationResult {
        // 1. Validate license key format
        guard licenseKey.starts(with: "SOLO-") else {
            return .invalid("Invalid license key format. Must start with SOLO-")
        }
        
        // 2. Contact server to verify license key (prevents duplicate sharing)
        let verificationResult = verifyLicenseWithServer(licenseKey)
        guard verificationResult.isValid else {
            return .invalid("License key not found or already revoked")
        }
        
        // 3. Check if license is already activated on different machine
        let currentHardware = HardwareIDGenerator
