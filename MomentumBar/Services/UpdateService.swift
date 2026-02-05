import Foundation
@preconcurrency import Combine
import Sparkle

@MainActor
final class UpdateService: ObservableObject {
    static let shared = UpdateService()

    private let updaterController: SPUStandardUpdaterController

    @Published var automaticallyChecksForUpdates: Bool

    private init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        automaticallyChecksForUpdates = updaterController.updater.automaticallyChecksForUpdates
    }

    func setAutomaticChecks(_ enabled: Bool) {
        updaterController.updater.automaticallyChecksForUpdates = enabled
        automaticallyChecksForUpdates = enabled
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}

