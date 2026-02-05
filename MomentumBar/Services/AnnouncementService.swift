import Foundation

@MainActor
final class AnnouncementService {
    static let shared = AnnouncementService()

    private let baseURL = "https://momentum-bar-production.up.railway.app/api/v1"
    private let session: URLSession
    private let decoder: JSONDecoder
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let seenAnnouncementIds = "com.momentumbar.announcements.seen"
        static let lastFetch = "com.momentumbar.announcements.lastFetch"
        static let cachedAnnouncements = "com.momentumbar.announcements.cache"
    }

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 20
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let formatterWithFraction = ISO8601DateFormatter()
            formatterWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatterWithFraction.date(from: value) {
                return date
            }
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: value) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(value)")
        }
    }

    func checkForAnnouncementsIfNeeded() async -> Announcement? {
        let shouldFetch = shouldFetchAnnouncements()
        let announcements = shouldFetch ? (await fetchAnnouncements()) : loadCachedAnnouncements()
        guard let announcements else { return nil }
        return nextAnnouncementToShow(from: announcements)
    }

    func markAnnouncementSeen(_ announcement: Announcement) {
        var seen = loadSeenIds()
        seen.insert(announcement.id)
        defaults.set(Array(seen), forKey: Keys.seenAnnouncementIds)
    }

    private func shouldFetchAnnouncements() -> Bool {
        guard let lastFetch = defaults.object(forKey: Keys.lastFetch) as? Date else {
            return true
        }
        return Date().timeIntervalSince(lastFetch) > 6 * 60 * 60
    }

    private func fetchAnnouncements() async -> [Announcement]? {
        guard let url = URL(string: baseURL + "/announcements") else { return nil }

        do {
            let (data, response) = try await session.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                return nil
            }

            struct Response: Decodable {
                let announcements: [Announcement]
            }

            let decoded = try decoder.decode(Response.self, from: data)
            defaults.set(Date(), forKey: Keys.lastFetch)
            cacheAnnouncements(decoded.announcements)
            return decoded.announcements
        } catch {
            return loadCachedAnnouncements()
        }
    }

    private func cacheAnnouncements(_ announcements: [Announcement]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(announcements) {
            defaults.set(data, forKey: Keys.cachedAnnouncements)
        }
    }

    private func loadCachedAnnouncements() -> [Announcement]? {
        guard let data = defaults.data(forKey: Keys.cachedAnnouncements) else { return nil }
        return try? decoder.decode([Announcement].self, from: data)
    }

    private func loadSeenIds() -> Set<Int> {
        let ids = defaults.array(forKey: Keys.seenAnnouncementIds) as? [Int] ?? []
        return Set(ids)
    }

    private func nextAnnouncementToShow(from announcements: [Announcement]) -> Announcement? {
        let currentVersion = SemanticVersion.current
        let now = Date()
        let seen = loadSeenIds()

        return announcements.first { announcement in
            guard !seen.contains(announcement.id) else { return false }

            if let startsAt = announcement.startsAt, startsAt > now { return false }
            if let endsAt = announcement.endsAt, endsAt < now { return false }

            if let minVersion = announcement.minAppVersion,
               let parsedMin = SemanticVersion(minVersion),
               currentVersion < parsedMin {
                return false
            }

            if let maxVersion = announcement.maxAppVersion,
               let parsedMax = SemanticVersion(maxVersion),
               currentVersion > parsedMax {
                return false
            }

            return true
        }
    }
}

struct SemanticVersion: Comparable {
    let major: Int
    let minor: Int
    let patch: Int

    static var current: SemanticVersion {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return SemanticVersion(version) ?? SemanticVersion(1, 0, 0)
    }

    init(_ major: Int, _ minor: Int, _ patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    init?(_ string: String) {
        let parts = string.split(separator: ".").map { Int($0) ?? 0 }
        guard parts.count >= 1 else { return nil }
        self.major = parts.count > 0 ? parts[0] : 0
        self.minor = parts.count > 1 ? parts[1] : 0
        self.patch = parts.count > 2 ? parts[2] : 0
    }

    static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}
