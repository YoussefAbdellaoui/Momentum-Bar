import Foundation
@preconcurrency import Combine
import Sparkle

final class UpdateUserDriverDelegate: NSObject, SPUStandardUserDriverDelegate {
    func standardUserDriverWillHandleError(_ error: Error) {
        Task { @MainActor in
            UpdateService.shared.setLastError(error.localizedDescription)
        }
    }
}

@MainActor
final class UpdateService: ObservableObject {
    static let shared = UpdateService()

    private let updaterController: SPUStandardUpdaterController

    @Published var automaticallyChecksForUpdates: Bool
    @Published var lastCheckedAt: Date?
    @Published var lastErrorMessage: String?
    private let userDriverDelegate = UpdateUserDriverDelegate()

    private init() {
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: userDriverDelegate)
        automaticallyChecksForUpdates = updaterController.updater.automaticallyChecksForUpdates
    }

    func setAutomaticChecks(_ enabled: Bool) {
        updaterController.updater.automaticallyChecksForUpdates = enabled
        automaticallyChecksForUpdates = enabled
    }

    func checkForUpdates() {
        lastCheckedAt = Date()
        lastErrorMessage = nil
        DiagnosticsService.shared.logUpdateCheck()
        updaterController.checkForUpdates(nil)
    }

    func setLastError(_ message: String) {
        lastErrorMessage = message
    }
}
