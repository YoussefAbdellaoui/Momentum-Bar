//
//  PomodoroService.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import Foundation
import UserNotifications
import Combine
import WidgetKit

// MARK: - Pomodoro State
enum PomodoroState: String, Codable {
    case idle
    case working
    case shortBreak
    case longBreak
    case paused

    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .working: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        case .paused: return "Paused"
        }
    }

    var color: String {
        switch self {
        case .idle: return "#8E8E93"
        case .working: return "#FF3B30"
        case .shortBreak: return "#34C759"
        case .longBreak: return "#007AFF"
        case .paused: return "#FF9500"
        }
    }
}

// MARK: - Pomodoro Session
struct PomodoroSession: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let type: PomodoroState
    let completedFully: Bool

    init(id: UUID = UUID(), startTime: Date, endTime: Date = Date(), type: PomodoroState, completedFully: Bool) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.type = type
        self.completedFully = completedFully
    }

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

// MARK: - Pomodoro Settings
struct PomodoroSettings: Codable, Equatable {
    var workDuration: Int = 25 // minutes
    var shortBreakDuration: Int = 5 // minutes
    var longBreakDuration: Int = 15 // minutes
    var sessionsUntilLongBreak: Int = 4
    var autoStartBreaks: Bool = true
    var autoStartWork: Bool = false
    var showNotifications: Bool = true
    var playSound: Bool = true

    static let `default` = PomodoroSettings()
}

// MARK: - Pomodoro Service
@MainActor
@Observable
final class PomodoroService {
    static let shared = PomodoroService()

    // State
    var state: PomodoroState = .idle
    var timeRemaining: TimeInterval = 0
    var completedSessions: Int = 0
    var totalSessionsToday: Int = 0
    var currentSessionStart: Date?

    // Settings
    var settings: PomodoroSettings = .default

    // History
    var todaySessions: [PomodoroSession] = []

    // Private
    private var timer: Timer?
    private var stateBeforePause: PomodoroState = .idle

    private init() {
        loadSettings()
        loadTodaySessions()
        resetTimer()
    }

    // MARK: - Timer Control
    func start() {
        if state == .idle {
            startWorkSession()
        } else if state == .paused {
            resume()
        }
        syncToWidget()
    }

    func pause() {
        guard state == .working || state == .shortBreak || state == .longBreak else { return }
        stateBeforePause = state
        state = .paused
        timer?.invalidate()
        timer = nil
        syncToWidget()
    }

    func resume() {
        guard state == .paused else { return }
        state = stateBeforePause
        startTimer()
        syncToWidget()
    }

    func stop() {
        // Record incomplete session if we were working
        if state == .working, let start = currentSessionStart {
            let session = PomodoroSession(
                startTime: start,
                endTime: Date(),
                type: .working,
                completedFully: false
            )
            todaySessions.append(session)
            saveTodaySessions()

            // Disable Focus Mode when stopping work session
            FocusModeService.shared.onPomodoroWorkEnded()
        }

        timer?.invalidate()
        timer = nil
        state = .idle
        completedSessions = 0
        currentSessionStart = nil
        resetTimer()
        syncToWidget()
    }

    func skip() {
        timer?.invalidate()
        timer = nil

        // Complete current phase
        if state == .working {
            completeWorkSession(skipped: true)
        } else if state == .shortBreak || state == .longBreak {
            completeBreak()
        }
        syncToWidget()
    }

    // MARK: - Session Management
    private func startWorkSession() {
        state = .working
        timeRemaining = TimeInterval(settings.workDuration * 60)
        currentSessionStart = Date()
        startTimer()

        // Enable Focus Mode if configured
        FocusModeService.shared.onPomodoroWorkStarted()
    }

    private func startShortBreak() {
        state = .shortBreak
        timeRemaining = TimeInterval(settings.shortBreakDuration * 60)
        currentSessionStart = Date()

        // Disable Focus Mode when entering break
        FocusModeService.shared.onPomodoroWorkEnded()

        if settings.autoStartBreaks {
            startTimer()
        }

        sendNotification(title: "Time for a break!", body: "You've completed a focus session. Take a \(settings.shortBreakDuration) minute break.")
    }

    private func startLongBreak() {
        state = .longBreak
        timeRemaining = TimeInterval(settings.longBreakDuration * 60)
        currentSessionStart = Date()

        // Disable Focus Mode when entering break
        FocusModeService.shared.onPomodoroWorkEnded()

        if settings.autoStartBreaks {
            startTimer()
        }

        sendNotification(title: "Long break time!", body: "Great work! You've completed \(settings.sessionsUntilLongBreak) sessions. Take a \(settings.longBreakDuration) minute break.")
    }

    private func completeWorkSession(skipped: Bool = false) {
        // Record session
        if let start = currentSessionStart {
            let session = PomodoroSession(
                startTime: start,
                endTime: Date(),
                type: .working,
                completedFully: !skipped
            )
            todaySessions.append(session)
            saveTodaySessions()
        }

        completedSessions += 1
        totalSessionsToday += 1

        // Determine next break type
        if completedSessions >= settings.sessionsUntilLongBreak {
            completedSessions = 0
            startLongBreak()
        } else {
            startShortBreak()
        }
    }

    private func completeBreak() {
        // Record break session
        if let start = currentSessionStart {
            let session = PomodoroSession(
                startTime: start,
                endTime: Date(),
                type: state,
                completedFully: true
            )
            todaySessions.append(session)
            saveTodaySessions()
        }

        if settings.autoStartWork {
            startWorkSession()
        } else {
            state = .idle
            resetTimer()
            sendNotification(title: "Break's over!", body: "Ready to start another focus session?")
        }
    }

    // MARK: - Timer
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        if let timer = timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    private func tick() {
        guard timeRemaining > 0 else {
            timer?.invalidate()
            timer = nil
            timerCompleted()
            return
        }

        timeRemaining -= 1

        // Sync to widget every 5 seconds to avoid excessive updates
        if Int(timeRemaining) % 5 == 0 {
            syncToWidget()
        }
    }

    private func timerCompleted() {
        if state == .working {
            completeWorkSession()
        } else if state == .shortBreak || state == .longBreak {
            completeBreak()
        }
    }

    private func resetTimer() {
        timeRemaining = TimeInterval(settings.workDuration * 60)
    }

    // MARK: - Widget Sync

    /// Sync current state to widget via App Group
    private func syncToWidget() {
        let totalDuration: TimeInterval
        switch state {
        case .working:
            totalDuration = TimeInterval(settings.workDuration * 60)
        case .shortBreak:
            totalDuration = TimeInterval(settings.shortBreakDuration * 60)
        case .longBreak:
            totalDuration = TimeInterval(settings.longBreakDuration * 60)
        case .paused:
            switch stateBeforePause {
            case .working:
                totalDuration = TimeInterval(settings.workDuration * 60)
            case .shortBreak:
                totalDuration = TimeInterval(settings.shortBreakDuration * 60)
            case .longBreak:
                totalDuration = TimeInterval(settings.longBreakDuration * 60)
            default:
                totalDuration = TimeInterval(settings.workDuration * 60)
            }
        case .idle:
            totalDuration = TimeInterval(settings.workDuration * 60)
        }

        // Calculate end time for running timers
        let endTime: Date?
        if state == .working || state == .shortBreak || state == .longBreak {
            endTime = Date().addingTimeInterval(timeRemaining)
        } else {
            endTime = nil
        }

        let sharedState = SharedPomodoroState(
            state: state.rawValue,
            timeRemaining: timeRemaining,
            totalDuration: totalDuration,
            completedSessions: completedSessions,
            totalSessionsToday: totalSessionsToday,
            sessionsUntilLongBreak: settings.sessionsUntilLongBreak,
            lastUpdated: Date(),
            endTime: endTime
        )

        StorageService.shared.savePomodoroState(sharedState)
    }

    // MARK: - Widget Command Observer

    /// Check for pending commands from widget
    func checkWidgetCommands() {
        guard let command = StorageService.shared.loadAndClearPomodoroCommand() else {
            return
        }

        switch command.command {
        case .start:
            start()
        case .pause:
            pause()
        case .stop:
            stop()
        case .skip:
            skip()
        }
    }

    /// Setup periodic check for widget commands (call from app activation)
    func setupWidgetCommandObserver() {
        // Check immediately
        checkWidgetCommands()

        // Also sync current state to widget
        syncToWidget()
    }

    // MARK: - Notifications
    private func sendNotification(title: String, body: String) {
        guard settings.showNotifications else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = settings.playSound ? .default : nil
        content.categoryIdentifier = "POMODORO"

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Persistence
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "com.momentumbar.pomodoroSettings"),
           let decoded = try? JSONDecoder().decode(PomodoroSettings.self, from: data) {
            settings = decoded
        }
    }

    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "com.momentumbar.pomodoroSettings")
        }
    }

    private func loadTodaySessions() {
        let calendar = Calendar.current

        if let data = UserDefaults.standard.data(forKey: "com.momentumbar.pomodoroSessions"),
           let decoded = try? JSONDecoder().decode([PomodoroSession].self, from: data) {
            // Filter to only today's sessions
            todaySessions = decoded.filter { calendar.isDateInToday($0.startTime) }
            totalSessionsToday = todaySessions.filter { $0.type == .working && $0.completedFully }.count
        }
    }

    private func saveTodaySessions() {
        // Keep last 7 days of sessions
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        var allSessions: [PomodoroSession] = []
        if let data = UserDefaults.standard.data(forKey: "com.momentumbar.pomodoroSessions"),
           let decoded = try? JSONDecoder().decode([PomodoroSession].self, from: data) {
            allSessions = decoded.filter { $0.startTime > weekAgo }
        }

        // Add today's sessions
        for session in todaySessions {
            if !allSessions.contains(where: { $0.id == session.id }) {
                allSessions.append(session)
            }
        }

        if let data = try? JSONEncoder().encode(allSessions) {
            UserDefaults.standard.set(data, forKey: "com.momentumbar.pomodoroSessions")
        }
    }

    // MARK: - Computed Properties
    var formattedTimeRemaining: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var progress: Double {
        let total: TimeInterval
        switch state {
        case .working:
            total = TimeInterval(settings.workDuration * 60)
        case .shortBreak:
            total = TimeInterval(settings.shortBreakDuration * 60)
        case .longBreak:
            total = TimeInterval(settings.longBreakDuration * 60)
        case .paused:
            switch stateBeforePause {
            case .working:
                total = TimeInterval(settings.workDuration * 60)
            case .shortBreak:
                total = TimeInterval(settings.shortBreakDuration * 60)
            case .longBreak:
                total = TimeInterval(settings.longBreakDuration * 60)
            default:
                total = TimeInterval(settings.workDuration * 60)
            }
        case .idle:
            total = TimeInterval(settings.workDuration * 60)
        }

        return 1.0 - (timeRemaining / total)
    }

    var todayFocusTime: TimeInterval {
        todaySessions
            .filter { $0.type == .working }
            .reduce(0) { $0 + $1.duration }
    }

    var formattedTodayFocusTime: String {
        let hours = Int(todayFocusTime) / 3600
        let minutes = (Int(todayFocusTime) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
