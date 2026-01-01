//
//  TimeZoneService.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation

final class TimeZoneService {
    static let shared = TimeZoneService()

    private let allTimeZones: [TimeZoneInfo]

    struct TimeZoneInfo: Identifiable {
        let id: String
        let identifier: String
        let cityName: String
        let countryName: String?
        let abbreviation: String
        let offset: Int
        let offsetString: String

        var displayName: String {
            if let country = countryName {
                return "\(cityName), \(country)"
            }
            return cityName
        }
    }

    private init() {
        // Pre-compute all timezone info for fast searching
        var zones: [TimeZoneInfo] = []

        for identifier in TimeZone.knownTimeZoneIdentifiers {
            guard let tz = TimeZone(identifier: identifier) else { continue }

            // Extract city name from identifier (e.g., "America/New_York" -> "New York")
            let components = identifier.components(separatedBy: "/")
            guard components.count >= 2 else { continue }

            let cityName = components.last?
                .replacingOccurrences(of: "_", with: " ") ?? identifier

            // Try to get country from region
            let region = components.first
            let countryName = Self.regionToCountry(region ?? "")

            let offset = tz.secondsFromGMT()
            let offsetString = Self.formatOffset(offset)

            zones.append(TimeZoneInfo(
                id: identifier,
                identifier: identifier,
                cityName: cityName,
                countryName: countryName,
                abbreviation: tz.abbreviation() ?? "UTC",
                offset: offset,
                offsetString: offsetString
            ))
        }

        // Sort by offset, then by city name
        allTimeZones = zones.sorted { first, second in
            if first.offset != second.offset {
                return first.offset < second.offset
            }
            return first.cityName < second.cityName
        }
    }

    // MARK: - Search
    func searchTimeZones(query: String) -> [TimeZoneInfo] {
        guard !query.isEmpty else { return [] }

        let lowercasedQuery = query.lowercased()

        return allTimeZones.filter { info in
            info.cityName.lowercased().contains(lowercasedQuery) ||
            info.identifier.lowercased().contains(lowercasedQuery) ||
            info.abbreviation.lowercased().contains(lowercasedQuery) ||
            (info.countryName?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }

    func popularTimeZones() -> [TimeZoneInfo] {
        let popularIdentifiers = [
            "America/New_York",
            "America/Los_Angeles",
            "America/Chicago",
            "Europe/London",
            "Europe/Paris",
            "Europe/Berlin",
            "Asia/Tokyo",
            "Asia/Shanghai",
            "Asia/Dubai",
            "Australia/Sydney",
            "Pacific/Auckland"
        ]

        return popularIdentifiers.compactMap { id in
            allTimeZones.first { $0.identifier == id }
        }
    }

    func getTimeZoneInfo(for identifier: String) -> TimeZoneInfo? {
        allTimeZones.first { $0.identifier == identifier }
    }

    // MARK: - Helpers
    private static func formatOffset(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = abs(seconds / 60) % 60

        if minutes == 0 {
            return hours >= 0 ? "UTC+\(hours)" : "UTC\(hours)"
        } else {
            let sign = hours >= 0 ? "+" : ""
            return "UTC\(sign)\(hours):\(String(format: "%02d", minutes))"
        }
    }

    private static func regionToCountry(_ region: String) -> String? {
        let regionMap: [String: String] = [
            "America": "Americas",
            "Europe": "Europe",
            "Asia": "Asia",
            "Africa": "Africa",
            "Australia": "Australia",
            "Pacific": "Pacific",
            "Atlantic": "Atlantic",
            "Indian": "Indian Ocean",
            "Antarctica": "Antarctica"
        ]
        return regionMap[region]
    }
}
