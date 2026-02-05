import Foundation

struct Announcement: Identifiable, Codable, Equatable {
    enum AnnouncementType: String, Codable {
        case info
        case warning
        case critical

        var accentColorName: String {
            switch self {
            case .info: return "accent"
            case .warning: return "warning"
            case .critical: return "critical"
            }
        }
    }

    let id: Int
    let title: String
    let body: String
    let type: AnnouncementType
    let linkUrl: String?
    let startsAt: Date?
    let endsAt: Date?
    let minAppVersion: String?
    let maxAppVersion: String?
    let createdAt: Date?

    var linkURL: URL? {
        guard let linkUrl else { return nil }
        return URL(string: linkUrl)
    }
}
