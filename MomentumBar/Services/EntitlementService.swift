//
//  EntitlementService.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation
import Security

/// Runtime entitlement checks to provide clear UI fallbacks.
final class EntitlementService {
    static let shared = EntitlementService()

    private let task: SecTask?

    private init() {
        task = SecTaskCreateFromSelf(nil)
    }

    func hasEntitlement(_ key: String) -> Bool {
        guard let task else { return false }
        guard let value = SecTaskCopyValueForEntitlement(task, key as CFString, nil) else {
            return false
        }

        if CFGetTypeID(value) == CFBooleanGetTypeID() {
            return CFBooleanGetValue(value as! CFBoolean)
        }

        if CFGetTypeID(value) == CFArrayGetTypeID() {
            let array = unsafeBitCast(value, to: CFArray.self)
            return CFArrayGetCount(array) > 0
        }

        return true
    }

    var hasCalendarAccessEntitlement: Bool {
        hasEntitlement("com.apple.security.personal-information.calendars")
    }

    var hasKeychainAccess: Bool {
        hasEntitlement("keychain-access-groups")
    }

    var hasAppGroupAccess: Bool {
        hasEntitlement("com.apple.security.application-groups")
    }
}
