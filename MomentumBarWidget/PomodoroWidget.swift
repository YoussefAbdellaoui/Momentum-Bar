//
//  PomodoroWidget.swift
//  MomentumBarWidget
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget Entry
struct PomodoroWidgetEntry: TimelineEntry {
    let date: Date
    let state: PomodoroWidgetState
    let timeRemaining: TimeInterval
    let totalDuration: TimeInterval
    let completedSessions: Int
    let totalSessionsToday: Int
    let sessionsUntilLongBreak: Int
    let endTime: Date?

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (timeRemaining / totalDuration)
    }

    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    static let placeholder = PomodoroWidgetEntry(
        date: Date(),
        state: .idle,
        timeRemaining: 25 * 60,
        totalDuration: 25 * 60,
        completedSessions: 0,
        totalSessionsToday: 0,
        sessionsUntilLongBreak: 4,
        endTime: nil
    )
}

// MARK: - Widget State (mirrors PomodoroState)
enum PomodoroWidgetState: String {
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

    var color: Color {
        switch self {
        case .idle: return Color(hex: "#8E8E93") ?? .gray
        case .working: return Color(hex: "#FF3B30") ?? .red
        case .shortBreak: return Color(hex: "#34C759") ?? .green
        case .longBreak: return Color(hex: "#007AFF") ?? .blue
        case .paused: return Color(hex: "#FF9500") ?? .orange
        }
    }

    var icon: String {
        switch self {
        case .idle: return "play.circle.fill"
        case .working: return "flame.fill"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "moon.fill"
        case .paused: return "pause.circle.fill"
        }
    }

    var isRunning: Bool {
        self == .working || self == .shortBreak || self == .longBreak
    }
}

// MARK: - Shared State Model (must match main app)
struct SharedPomodoroState: Codable {
    let state: String
    let timeRemaining: TimeInterval
    let totalDuration: TimeInterval
    let completedSessions: Int
    let totalSessionsToday: Int
    let sessionsUntilLongBreak: Int
    let lastUpdated: Date
    let endTime: Date?
}

// MARK: - App Group Constants
private enum PomodoroAppGroup {
    static let suiteName = "group.com.momentumbar.shared"
    static let stateKey = "com.momentumbar.pomodoro.state"
    static let commandKey = "com.momentumbar.pomodoro.command"
}

// MARK: - Timeline Provider
struct PomodoroProvider: TimelineProvider {
    func placeholder(in context: Context) -> PomodoroWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (PomodoroWidgetEntry) -> Void) {
        completion(loadEntry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PomodoroWidgetEntry>) -> Void) {
        let currentDate = Date()
        var entries: [PomodoroWidgetEntry] = []

        let entry = loadEntry(at: currentDate)

        if entry.state.isRunning, let endTime = entry.endTime {
            // Timer is running - generate entries for countdown
            let secondsRemaining = Int(entry.timeRemaining)

            // Generate entries every 5 seconds for efficiency
            for secondOffset in stride(from: 0, to: min(secondsRemaining, 300), by: 5) {
                let entryDate = currentDate.addingTimeInterval(TimeInterval(secondOffset))
                let remaining = entry.timeRemaining - TimeInterval(secondOffset)

                if remaining > 0 {
                    entries.append(PomodoroWidgetEntry(
                        date: entryDate,
                        state: entry.state,
                        timeRemaining: remaining,
                        totalDuration: entry.totalDuration,
                        completedSessions: entry.completedSessions,
                        totalSessionsToday: entry.totalSessionsToday,
                        sessionsUntilLongBreak: entry.sessionsUntilLongBreak,
                        endTime: endTime
                    ))
                }
            }

            // Refresh after 5 minutes or when timer completes
            let refreshDate = min(
                currentDate.addingTimeInterval(300),
                endTime.addingTimeInterval(1)
            )
            completion(Timeline(entries: entries.isEmpty ? [entry] : entries, policy: .after(refreshDate)))
        } else {
            // Timer not running - single entry, refresh every 15 minutes
            entries.append(entry)
            completion(Timeline(entries: entries, policy: .after(currentDate.addingTimeInterval(900))))
        }
    }

    private func loadEntry(at date: Date) -> PomodoroWidgetEntry {
        guard let defaults = UserDefaults(suiteName: PomodoroAppGroup.suiteName),
              let data = defaults.data(forKey: PomodoroAppGroup.stateKey),
              let sharedState = try? JSONDecoder().decode(SharedPomodoroState.self, from: data) else {
            return .placeholder
        }

        let state = PomodoroWidgetState(rawValue: sharedState.state) ?? .idle

        // Calculate current time remaining based on end time
        var timeRemaining = sharedState.timeRemaining
        if state.isRunning, let endTime = sharedState.endTime {
            timeRemaining = max(0, endTime.timeIntervalSince(date))
        }

        return PomodoroWidgetEntry(
            date: date,
            state: state,
            timeRemaining: timeRemaining,
            totalDuration: sharedState.totalDuration,
            completedSessions: sharedState.completedSessions,
            totalSessionsToday: sharedState.totalSessionsToday,
            sessionsUntilLongBreak: sharedState.sessionsUntilLongBreak,
            endTime: sharedState.endTime
        )
    }
}

// MARK: - Widget Entry View
struct PomodoroWidgetEntryView: View {
    var entry: PomodoroProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallPomodoroView(entry: entry)
        case .systemMedium:
            MediumPomodoroView(entry: entry)
        case .systemLarge:
            LargePomodoroView(entry: entry)
        default:
            SmallPomodoroView(entry: entry)
        }
    }
}

// MARK: - Small Widget View
struct SmallPomodoroView: View {
    let entry: PomodoroWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 6)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(
                        entry.state.color,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text(entry.formattedTime)
                        .font(.system(size: 18, weight: .semibold, design: .monospaced))

                    Image(systemName: entry.state.icon)
                        .font(.system(size: 10))
                        .foregroundStyle(entry.state.color)
                }
            }

            // State Label
            Text(entry.state.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(entry.state.color)

            // Sessions
            HStack(spacing: 3) {
                ForEach(0..<entry.sessionsUntilLongBreak, id: \.self) { index in
                    Circle()
                        .fill(index < entry.completedSessions ? Color.green : Color.primary.opacity(0.2))
                        .frame(width: 6, height: 6)
                }
            }
        }
        .padding()
    }
}

// MARK: - Medium Widget View
struct MediumPomodoroView: View {
    let entry: PomodoroWidgetEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(
                        entry.state.color,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text(entry.formattedTime)
                        .font(.system(size: 22, weight: .semibold, design: .monospaced))

                    Image(systemName: entry.state.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(entry.state.color)
                }
            }

            // Right: Info
            VStack(alignment: .leading, spacing: 8) {
                // State
                Text(entry.state.displayName.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(entry.state.color)

                // Session Progress
                HStack(spacing: 4) {
                    ForEach(0..<entry.sessionsUntilLongBreak, id: \.self) { index in
                        Circle()
                            .fill(index < entry.completedSessions ? Color.green : Color.primary.opacity(0.2))
                            .frame(width: 8, height: 8)
                    }
                    Text("until break")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Today's Stats
                HStack(spacing: 16) {
                    Label("\(entry.totalSessionsToday)", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)

                    Label(formattedFocusTime, systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }

    private var formattedFocusTime: String {
        let totalMinutes = entry.totalSessionsToday * 25
        if totalMinutes >= 60 {
            return "\(totalMinutes / 60)h \(totalMinutes % 60)m"
        }
        return "\(totalMinutes)m"
    }
}

// MARK: - Large Widget View
struct LargePomodoroView: View {
    let entry: PomodoroWidgetEntry

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Label("Pomodoro Timer", systemImage: "timer")
                    .font(.headline)
                Spacer()
                Text(entry.state.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(entry.state.color)
            }

            Divider()

            // Main Timer
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.1), lineWidth: 12)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(
                        entry.state.color,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text(entry.formattedTime)
                        .font(.system(size: 32, weight: .semibold, design: .monospaced))

                    Image(systemName: entry.state.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(entry.state.color)
                }
            }

            // Session Progress
            HStack(spacing: 6) {
                ForEach(0..<entry.sessionsUntilLongBreak, id: \.self) { index in
                    Circle()
                        .fill(index < entry.completedSessions ? Color.green : Color.primary.opacity(0.2))
                        .frame(width: 12, height: 12)
                }
            }

            Text("\(entry.completedSessions) of \(entry.sessionsUntilLongBreak) until long break")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            // Today's Stats
            HStack(spacing: 24) {
                StatView(
                    icon: "flame.fill",
                    value: "\(entry.totalSessionsToday)",
                    label: "Sessions",
                    color: .orange
                )

                StatView(
                    icon: "clock.fill",
                    value: formattedFocusTime,
                    label: "Focus Time",
                    color: .blue
                )
            }

            // Control Buttons (Interactive)
            if #available(macOS 14.0, iOS 17.0, *) {
                HStack(spacing: 16) {
                    if entry.state == .idle {
                        Button(intent: StartPomodoroIntent()) {
                            Label("Start", systemImage: "play.fill")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    } else if entry.state == .paused {
                        Button(intent: StartPomodoroIntent()) {
                            Label("Resume", systemImage: "play.fill")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)

                        Button(intent: StopPomodoroIntent()) {
                            Label("Stop", systemImage: "stop.fill")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button(intent: PausePomodoroIntent()) {
                            Label("Pause", systemImage: "pause.fill")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.bordered)

                        Button(intent: SkipPomodoroIntent()) {
                            Label("Skip", systemImage: "forward.fill")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
        .padding()
    }

    private var formattedFocusTime: String {
        let totalMinutes = entry.totalSessionsToday * 25
        if totalMinutes >= 60 {
            return "\(totalMinutes / 60)h \(totalMinutes % 60)m"
        }
        return "\(totalMinutes)m"
    }
}

struct StatView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - App Intents for Interactive Buttons

struct StartPomodoroIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Pomodoro"
    static var description = IntentDescription("Start or resume the Pomodoro timer")

    func perform() async throws -> some IntentResult {
        savePomodoroCommand(.start)
        return .result()
    }
}

struct PausePomodoroIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Pomodoro"
    static var description = IntentDescription("Pause the Pomodoro timer")

    func perform() async throws -> some IntentResult {
        savePomodoroCommand(.pause)
        return .result()
    }
}

struct StopPomodoroIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Pomodoro"
    static var description = IntentDescription("Stop the Pomodoro timer")

    func perform() async throws -> some IntentResult {
        savePomodoroCommand(.stop)
        return .result()
    }
}

struct SkipPomodoroIntent: AppIntent {
    static var title: LocalizedStringResource = "Skip Pomodoro Phase"
    static var description = IntentDescription("Skip to the next Pomodoro phase")

    func perform() async throws -> some IntentResult {
        savePomodoroCommand(.skip)
        return .result()
    }
}

// Helper to save command
private func savePomodoroCommand(_ command: WidgetPomodoroCommand) {
    guard let defaults = UserDefaults(suiteName: PomodoroAppGroup.suiteName) else { return }

    let widgetCommand = WidgetCommand(command: command, timestamp: Date())

    if let data = try? JSONEncoder().encode(widgetCommand) {
        defaults.set(data, forKey: PomodoroAppGroup.commandKey)
    }
}

// Command types (must match main app)
private enum WidgetPomodoroCommand: String, Codable {
    case start, pause, stop, skip
}

private struct WidgetCommand: Codable {
    let command: WidgetPomodoroCommand
    let timestamp: Date
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Widget Definition
struct PomodoroWidget: Widget {
    let kind: String = "PomodoroWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PomodoroProvider()) { entry in
            PomodoroWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Pomodoro Timer")
        .description("Track your focus sessions and breaks.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    PomodoroWidget()
} timeline: {
    PomodoroWidgetEntry(
        date: .now,
        state: .working,
        timeRemaining: 15 * 60 + 30,
        totalDuration: 25 * 60,
        completedSessions: 2,
        totalSessionsToday: 5,
        sessionsUntilLongBreak: 4,
        endTime: Date().addingTimeInterval(15 * 60 + 30)
    )
}

#Preview(as: .systemMedium) {
    PomodoroWidget()
} timeline: {
    PomodoroWidgetEntry(
        date: .now,
        state: .shortBreak,
        timeRemaining: 3 * 60,
        totalDuration: 5 * 60,
        completedSessions: 3,
        totalSessionsToday: 8,
        sessionsUntilLongBreak: 4,
        endTime: Date().addingTimeInterval(3 * 60)
    )
}

#Preview(as: .systemLarge) {
    PomodoroWidget()
} timeline: {
    PomodoroWidgetEntry(
        date: .now,
        state: .idle,
        timeRemaining: 25 * 60,
        totalDuration: 25 * 60,
        completedSessions: 0,
        totalSessionsToday: 3,
        sessionsUntilLongBreak: 4,
        endTime: nil
    )
}
