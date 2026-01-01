//
//  TimeZoneEntry.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation
import SwiftUI

struct TimeZoneEntry: Identifiable, Codable, Hashable {
    let id: UUID
    var identifier: String
    var customName: String?
    var colorHex: String?
    var order: Int
    var groupID: UUID?

    init(
        id: UUID = UUID(),
        identifier: String,
        customName: String? = nil,
        colorHex: String? = nil,
        order: Int = 0,
        groupID: UUID? = nil
    ) {
        self.id = id
        self.identifier = identifier
        self.customName = customName
        self.colorHex = colorHex
        self.order = order
        self.groupID = groupID
    }

    var timeZone: TimeZone? {
        TimeZone(identifier: identifier)
    }

    var displayName: String {
        if let custom = customName, !custom.isEmpty {
            return custom
        }
        return timeZone?.localizedName(for: .shortGeneric, locale: .current)
            ?? timeZone?.abbreviation()
            ?? identifier.components(separatedBy: "/").last ?? identifier
    }

    var cityName: String {
        identifier.components(separatedBy: "/").last?.replacingOccurrences(of: "_", with: " ") ?? identifier
    }

    var abbreviation: String {
        timeZone?.abbreviation() ?? "UTC"
    }

    var currentOffset: String {
        guard let tz = timeZone else { return "" }
        let seconds = tz.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = abs(seconds / 60) % 60
        if minutes == 0 {
            return hours >= 0 ? "UTC+\(hours)" : "UTC\(hours)"
        } else {
            return hours >= 0 ? "UTC+\(hours):\(String(format: "%02d", minutes))" : "UTC\(hours):\(String(format: "%02d", minutes))"
        }
    }

    var color: Color {
        guard let hex = colorHex else { return .blue }
        return Color(hex: hex) ?? .blue
    }
}

// MARK: - Timezone Group
struct TimezoneGroup: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var colorHex: String
    var icon: String
    var order: Int

    init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#007AFF",
        icon: String = "folder",
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
        self.order = order
    }

    var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    static let defaultGroups: [TimezoneGroup] = [
        TimezoneGroup(name: "Work", colorHex: "#007AFF", icon: "briefcase", order: 0),
        TimezoneGroup(name: "Personal", colorHex: "#34C759", icon: "person", order: 1),
        TimezoneGroup(name: "Clients", colorHex: "#FF9500", icon: "person.2", order: 2)
    ]
}

// MARK: - Color Extension for Hex Support
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r, g, b: Double
        switch hexSanitized.count {
        case 6:
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
        case 8:
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
        default:
            return nil
        }

        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String? {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
