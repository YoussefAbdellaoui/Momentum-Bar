//
//  SunriseSunsetService.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation

/// Service for calculating accurate sunrise and sunset times based on location
/// Uses the NOAA Solar Calculator algorithm
final class SunriseSunsetService {
    static let shared = SunriseSunsetService()

    private init() {}

    // MARK: - Main API

    /// Determines if it's currently daytime at the given timezone
    /// - Parameters:
    ///   - timeZone: The timezone to check
    ///   - date: The date/time to check (defaults to now)
    /// - Returns: True if it's daytime, false if nighttime
    func isDaytime(for timeZone: TimeZone, at date: Date = Date()) -> Bool {
        guard let coordinates = coordinates(for: timeZone) else {
            // Fallback to simple hour-based calculation
            return isSimpleDaytime(for: timeZone, at: date)
        }

        guard let (sunrise, sunset) = sunriseSunset(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            date: date,
            timeZone: timeZone
        ) else {
            return isSimpleDaytime(for: timeZone, at: date)
        }

        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents(in: timeZone, from: date)
        let sunriseComponents = calendar.dateComponents(in: timeZone, from: sunrise)
        let sunsetComponents = calendar.dateComponents(in: timeZone, from: sunset)

        guard let currentMinutes = totalMinutes(from: currentComponents),
              let sunriseMinutes = totalMinutes(from: sunriseComponents),
              let sunsetMinutes = totalMinutes(from: sunsetComponents) else {
            return isSimpleDaytime(for: timeZone, at: date)
        }

        return currentMinutes >= sunriseMinutes && currentMinutes < sunsetMinutes
    }

    /// Gets sunrise and sunset times for a given timezone and date
    /// - Parameters:
    ///   - timeZone: The timezone
    ///   - date: The date to calculate for
    /// - Returns: Tuple of (sunrise, sunset) dates, or nil if calculation fails
    func getSunriseSunset(for timeZone: TimeZone, on date: Date = Date()) -> (sunrise: Date, sunset: Date)? {
        guard let coordinates = coordinates(for: timeZone) else {
            return nil
        }

        return sunriseSunset(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            date: date,
            timeZone: timeZone
        )
    }

    // MARK: - Fallback Simple Calculation

    private func isSimpleDaytime(for timeZone: TimeZone, at date: Date) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: timeZone, from: date)
        let hour = components.hour ?? 12
        return hour >= 6 && hour < 18
    }

    private func totalMinutes(from components: DateComponents) -> Int? {
        guard let hour = components.hour, let minute = components.minute else {
            return nil
        }
        return hour * 60 + minute
    }

    // MARK: - NOAA Solar Calculator Algorithm

    /// Calculates sunrise and sunset using the NOAA algorithm
    private func sunriseSunset(
        latitude: Double,
        longitude: Double,
        date: Date,
        timeZone: TimeZone
    ) -> (sunrise: Date, sunset: Date)? {
        let calendar = Calendar.current
        let components = calendar.dateComponents(in: timeZone, from: date)

        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return nil
        }

        // Calculate Julian Day
        let jd = julianDay(year: year, month: month, day: day)

        // Calculate time offset from UTC in hours
        let tzOffset = Double(timeZone.secondsFromGMT(for: date)) / 3600.0

        // Calculate sunrise and sunset times
        guard let sunriseTime = calculateSunTime(
            jd: jd,
            latitude: latitude,
            longitude: longitude,
            tzOffset: tzOffset,
            isSunrise: true
        ),
        let sunsetTime = calculateSunTime(
            jd: jd,
            latitude: latitude,
            longitude: longitude,
            tzOffset: tzOffset,
            isSunrise: false
        ) else {
            return nil
        }

        // Convert decimal hours to Date
        let sunriseDate = dateFromDecimalHours(sunriseTime, on: date, timeZone: timeZone)
        let sunsetDate = dateFromDecimalHours(sunsetTime, on: date, timeZone: timeZone)

        guard let sunrise = sunriseDate, let sunset = sunsetDate else {
            return nil
        }

        return (sunrise, sunset)
    }

    private func julianDay(year: Int, month: Int, day: Int) -> Double {
        var y = year
        var m = month

        if m <= 2 {
            y -= 1
            m += 12
        }

        let a = Int(Double(y) / 100.0)
        let b = 2 - a + Int(Double(a) / 4.0)

        return Double(Int(365.25 * Double(y + 4716))) +
               Double(Int(30.6001 * Double(m + 1))) +
               Double(day) + Double(b) - 1524.5
    }

    private func calculateSunTime(
        jd: Double,
        latitude: Double,
        longitude: Double,
        tzOffset: Double,
        isSunrise: Bool
    ) -> Double? {
        // Julian Century
        let t = (jd - 2451545.0) / 36525.0

        // Geometric Mean Longitude of Sun (degrees)
        var l0 = 280.46646 + t * (36000.76983 + 0.0003032 * t)
        while l0 > 360 { l0 -= 360 }
        while l0 < 0 { l0 += 360 }

        // Geometric Mean Anomaly of Sun (degrees)
        var m = 357.52911 + t * (35999.05029 - 0.0001537 * t)
        while m > 360 { m -= 360 }
        while m < 0 { m += 360 }

        // Eccentricity of Earth's Orbit
        let e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)

        // Equation of Center
        let mRad = m * .pi / 180
        let c = sin(mRad) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
                sin(2 * mRad) * (0.019993 - 0.000101 * t) +
                sin(3 * mRad) * 0.000289

        // Sun True Longitude
        let sunLong = l0 + c

        // Sun Apparent Longitude
        let omega = 125.04 - 1934.136 * t
        let lambda = sunLong - 0.00569 - 0.00478 * sin(omega * .pi / 180)

        // Mean Obliquity of Ecliptic
        let seconds = 21.448 - t * (46.8150 + t * (0.00059 - t * 0.001813))
        let e0 = 23.0 + (26.0 + seconds / 60.0) / 60.0

        // Obliquity Correction
        let epsilon = e0 + 0.00256 * cos(omega * .pi / 180)

        // Sun Declination
        let lambdaRad = lambda * .pi / 180
        let epsilonRad = epsilon * .pi / 180
        let declination = asin(sin(epsilonRad) * sin(lambdaRad)) * 180 / .pi

        // Equation of Time (minutes)
        let y = tan(epsilonRad / 2) * tan(epsilonRad / 2)
        let l0Rad = l0 * .pi / 180
        let eqTime = 4 * (y * sin(2 * l0Rad) -
                         2 * e * sin(mRad) +
                         4 * e * y * sin(mRad) * cos(2 * l0Rad) -
                         0.5 * y * y * sin(4 * l0Rad) -
                         1.25 * e * e * sin(2 * mRad)) * 180 / .pi

        // Hour Angle
        let latRad = latitude * .pi / 180
        let declRad = declination * .pi / 180
        let zenith = 90.833 // Official zenith for sunrise/sunset

        let cosHA = (cos(zenith * .pi / 180) / (cos(latRad) * cos(declRad))) -
                    tan(latRad) * tan(declRad)

        // Check if sun never rises or sets at this location
        if cosHA > 1 || cosHA < -1 {
            return nil
        }

        var ha = acos(cosHA) * 180 / .pi

        if isSunrise {
            ha = -ha
        }

        // Solar Noon
        let solarNoon = (720 - 4 * longitude - eqTime + tzOffset * 60) / 1440

        // Sunrise/Sunset time in fraction of day
        let time = solarNoon + (ha * 4) / 1440

        // Convert to hours
        return time * 24
    }

    private func dateFromDecimalHours(_ hours: Double, on date: Date, timeZone: TimeZone) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents(in: timeZone, from: date)

        let totalMinutes = Int(hours * 60)
        components.hour = totalMinutes / 60
        components.minute = totalMinutes % 60
        components.second = 0

        return calendar.date(from: components)
    }

    // MARK: - Timezone to Coordinates Mapping

    /// Returns approximate coordinates for a timezone based on its major city
    func coordinates(for timeZone: TimeZone) -> (latitude: Double, longitude: Double)? {
        let identifier = timeZone.identifier

        // Check the lookup table
        if let coords = timezoneCoordinates[identifier] {
            return coords
        }

        // Try to extract region and find a match
        let components = identifier.split(separator: "/")
        if components.count >= 2 {
            let city = String(components.last!)
            // Search for partial matches
            for (key, coords) in timezoneCoordinates {
                if key.hasSuffix(city) {
                    return coords
                }
            }
        }

        return nil
    }

    /// Lookup table mapping timezone identifiers to their primary city coordinates
    private let timezoneCoordinates: [String: (latitude: Double, longitude: Double)] = [
        // Africa
        "Africa/Abidjan": (5.3599, -4.0083),
        "Africa/Accra": (5.6037, -0.1870),
        "Africa/Addis_Ababa": (9.0320, 38.7469),
        "Africa/Algiers": (36.7372, 3.0869),
        "Africa/Cairo": (30.0444, 31.2357),
        "Africa/Casablanca": (33.5731, -7.5898),
        "Africa/Johannesburg": (-26.2041, 28.0473),
        "Africa/Lagos": (6.4541, 3.3947),
        "Africa/Nairobi": (-1.2921, 36.8219),
        "Africa/Tunis": (36.8065, 10.1815),

        // America
        "America/Anchorage": (61.2181, -149.9003),
        "America/Argentina/Buenos_Aires": (-34.6037, -58.3816),
        "America/Bogota": (4.7110, -74.0721),
        "America/Chicago": (41.8781, -87.6298),
        "America/Denver": (39.7392, -104.9903),
        "America/Detroit": (42.3314, -83.0458),
        "America/Halifax": (44.6488, -63.5752),
        "America/Havana": (23.1136, -82.3666),
        "America/Los_Angeles": (34.0522, -118.2437),
        "America/Mexico_City": (19.4326, -99.1332),
        "America/New_York": (40.7128, -74.0060),
        "America/Phoenix": (33.4484, -112.0740),
        "America/Sao_Paulo": (-23.5505, -46.6333),
        "America/Santiago": (-33.4489, -70.6693),
        "America/Toronto": (43.6532, -79.3832),
        "America/Vancouver": (49.2827, -123.1207),

        // Asia
        "Asia/Bangkok": (13.7563, 100.5018),
        "Asia/Beirut": (33.8938, 35.5018),
        "Asia/Colombo": (6.9271, 79.8612),
        "Asia/Dhaka": (23.8103, 90.4125),
        "Asia/Dubai": (25.2048, 55.2708),
        "Asia/Ho_Chi_Minh": (10.8231, 106.6297),
        "Asia/Hong_Kong": (22.3193, 114.1694),
        "Asia/Istanbul": (41.0082, 28.9784),
        "Asia/Jakarta": (-6.2088, 106.8456),
        "Asia/Jerusalem": (31.7683, 35.2137),
        "Asia/Karachi": (24.8607, 67.0011),
        "Asia/Kolkata": (22.5726, 88.3639),
        "Asia/Kuala_Lumpur": (3.1390, 101.6869),
        "Asia/Manila": (14.5995, 120.9842),
        "Asia/Mumbai": (19.0760, 72.8777),
        "Asia/Riyadh": (24.7136, 46.6753),
        "Asia/Seoul": (37.5665, 126.9780),
        "Asia/Shanghai": (31.2304, 121.4737),
        "Asia/Singapore": (1.3521, 103.8198),
        "Asia/Taipei": (25.0330, 121.5654),
        "Asia/Tehran": (35.6892, 51.3890),
        "Asia/Tokyo": (35.6762, 139.6503),

        // Australia
        "Australia/Adelaide": (-34.9285, 138.6007),
        "Australia/Brisbane": (-27.4705, 153.0260),
        "Australia/Darwin": (-12.4634, 130.8456),
        "Australia/Hobart": (-42.8821, 147.3272),
        "Australia/Melbourne": (-37.8136, 144.9631),
        "Australia/Perth": (-31.9505, 115.8605),
        "Australia/Sydney": (-33.8688, 151.2093),

        // Europe
        "Europe/Amsterdam": (52.3676, 4.9041),
        "Europe/Athens": (37.9838, 23.7275),
        "Europe/Berlin": (52.5200, 13.4050),
        "Europe/Brussels": (50.8503, 4.3517),
        "Europe/Bucharest": (44.4268, 26.1025),
        "Europe/Budapest": (47.4979, 19.0402),
        "Europe/Copenhagen": (55.6761, 12.5683),
        "Europe/Dublin": (53.3498, -6.2603),
        "Europe/Helsinki": (60.1699, 24.9384),
        "Europe/Lisbon": (38.7223, -9.1393),
        "Europe/London": (51.5074, -0.1278),
        "Europe/Madrid": (40.4168, -3.7038),
        "Europe/Moscow": (55.7558, 37.6173),
        "Europe/Oslo": (59.9139, 10.7522),
        "Europe/Paris": (48.8566, 2.3522),
        "Europe/Prague": (50.0755, 14.4378),
        "Europe/Rome": (41.9028, 12.4964),
        "Europe/Stockholm": (59.3293, 18.0686),
        "Europe/Vienna": (48.2082, 16.3738),
        "Europe/Warsaw": (52.2297, 21.0122),
        "Europe/Zurich": (47.3769, 8.5417),

        // Pacific
        "Pacific/Auckland": (-36.8485, 174.7633),
        "Pacific/Fiji": (-18.1416, 178.4419),
        "Pacific/Honolulu": (21.3069, -157.8583),
        "Pacific/Sydney": (-33.8688, 151.2093),

        // Indian Ocean
        "Indian/Maldives": (3.2028, 73.2207),
        "Indian/Mauritius": (-20.3484, 57.5522),

        // Atlantic
        "Atlantic/Reykjavik": (64.1466, -21.9426),

        // Common aliases/abbreviations
        "GMT": (51.5074, -0.1278),
        "UTC": (51.5074, -0.1278),
        "EST": (40.7128, -74.0060),
        "PST": (34.0522, -118.2437),
        "CST": (41.8781, -87.6298),
        "MST": (39.7392, -104.9903),
    ]
}
