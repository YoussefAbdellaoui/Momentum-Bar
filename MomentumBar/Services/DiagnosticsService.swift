//
//  DiagnosticsService.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation

final class DiagnosticsService {
    static let shared = DiagnosticsService()

    private let fileManager = FileManager.default
    private let logFileName = "diagnostics.log"

    private init() {}

    func log(_ message: String, category: String = "app") {
        guard StorageService.shared.loadPreferences().enableLocalDiagnostics else { return }

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] [\(category)] \(message)\n"

        guard let url = logFileURL() else { return }

        if !fileManager.fileExists(atPath: url.path) {
            fileManager.createFile(atPath: url.path, contents: nil)
        }

        do {
            let handle = try FileHandle(forWritingTo: url)
            try handle.seekToEnd()
            if let data = line.data(using: .utf8) {
                try handle.write(contentsOf: data)
            }
            try handle.close()
        } catch {
            // Avoid recursive logging failures
        }
    }

    func logAppLaunch() {
        log("App launched", category: "lifecycle")
    }

    func logAppTerminate() {
        log("App terminated", category: "lifecycle")
    }

    func logUpdateCheck() {
        log("Manual update check started", category: "updates")
    }

    private func logFileURL() -> URL? {
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }

        let dir = appSupport.appendingPathComponent("MomentumBar", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        return dir.appendingPathComponent(logFileName)
    }
}
