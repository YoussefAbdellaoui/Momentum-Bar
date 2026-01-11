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
    var isPinnedToMenuBar: Bool
    var teammates: [String]

    init(
        id: UUID = UUID(),
        identifier: String,
        customName: String? = nil,
        colorHex: String? = nil,
        order: Int = 0,
        groupID: UUID? = nil,
        isPinnedToMenuBar: Bool = false,
        teammates: [String] = []
    ) {
        self.id = id
        self.identifier = identifier
        self.customName = customName
        self.colorHex = colorHex
        self.order = order
        self.groupID = groupID
        self.isPinnedToMenuBar = isPinnedToMenuBar
        self.teammates = teammates
    }

    // Custom decoder to handle migration from old data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        identifier = try container.decode(String.self, forKey: .identifier)
        customName = try container.decodeIfPresent(String.self, forKey: .customName)
        colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex)
        order = try container.decode(Int.self, forKey: .order)
        groupID = try container.decodeIfPresent(UUID.self, forKey: .groupID)
        isPinnedToMenuBar = try container.decodeIfPresent(Bool.self, forKey: .isPinnedToMenuBar) ?? false
        teammates = try container.decodeIfPresent([String].self, forKey: .teammates) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case id, identifier, customName, colorHex, order, groupID, isPinnedToMenuBar, teammates
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

    /// Short city name for menu bar display (e.g., NYC, LON, TYO)
    var shortCityName: String {
        // Use custom name if set and short enough
        if let custom = customName, !custom.isEmpty, custom.count <= 5 {
            return custom.uppercased()
        }

        // Map common cities to abbreviations
        let abbreviations: [String: String] = [
            "New_York": "NYC",
            "Los_Angeles": "LA",
            "San_Francisco": "SF",
            "London": "LON",
            "Tokyo": "TYO",
            "Paris": "PAR",
            "Berlin": "BER",
            "Sydney": "SYD",
            "Singapore": "SIN",
            "Hong_Kong": "HKG",
            "Dubai": "DXB",
            "Chicago": "CHI",
            "Toronto": "TOR",
            "Mumbai": "BOM",
            "Shanghai": "SHA",
            "Beijing": "PEK",
            "Melbourne": "MEL",
            "Auckland": "AKL",
            "Seoul": "SEL",
            "Amsterdam": "AMS",
            "Madrid": "MAD",
            "Rome": "ROM",
            "Moscow": "MOW",
            "Bangkok": "BKK",
            "Jakarta": "JKT",
            "Cairo": "CAI",
            "Johannesburg": "JNB",
            "Sao_Paulo": "SAO",
            "Mexico_City": "MEX",
            "Vancouver": "YVR",
            "Denver": "DEN",
            "Phoenix": "PHX",
            "Seattle": "SEA",
            "Miami": "MIA",
            "Boston": "BOS",
            "Dallas": "DFW",
            "Atlanta": "ATL"
        ]

        let city = identifier.components(separatedBy: "/").last ?? identifier
        if let abbr = abbreviations[city] {
            return abbr
        }

        // Fallback: first 3 characters of city name, uppercase
        let cleanCity = city.replacingOccurrences(of: "_", with: "")
        return String(cleanCity.prefix(3)).uppercased()
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
