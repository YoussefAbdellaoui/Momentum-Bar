//
//  PomodoroView.swift
//  MomentumBar
//
//  Created by Claude on behalf of Youssef Abdellaoui.
//

import SwiftUI

struct PomodoroView: View {
    @State private var pomodoro = PomodoroService.shared
    @State private var showSettings = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Timer Display
                TimerCircle(
                    progress: pomodoro.progress,
                    timeRemaining: pomodoro.formattedTimeRemaining,
                    state: pomodoro.state
                )

                // Session Info
                SessionInfoBar(
                    completedSessions: pomodoro.completedSessions,
                    totalToday: pomodoro.totalSessionsToday,
                    sessionsUntilLongBreak: pomodoro.settings.sessionsUntilLongBreak
                )

                // Controls
                ControlButtons(
                    state: pomodoro.state,
                    onStart: { pomodoro.start() },
                    onPause: { pomodoro.pause() },
                    onStop: { pomodoro.stop() },
                    onSkip: { pomodoro.skip() }
                )

                Divider()
                    .padding(.horizontal)

                // Today's Stats
                TodayStats(
                    focusTime: pomodoro.formattedTodayFocusTime,
                    sessionsCompleted: pomodoro.totalSessionsToday
                )

                // Settings Button
                Button {
                    showSettings = true
                } label: {
                    HStack {
                        Image(systemName: "gearshape")
                        Text("Timer Settings")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .padding(.top, 8)
        }
        .sheet(isPresented: $showSettings) {
            PomodoroSettingsSheet(settings: $pomodoro.settings) {
                pomodoro.saveSettings()
            }
        }
    }
}

// MARK: - Timer Circle
struct TimerCircle: View {
    let progress: Double
    let timeRemaining: String
    let state: PomodoroState
    @State private var themeManager = ThemeManager.shared

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: 8)
                .frame(width: 160, height: 160)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    stateColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)

            // Center content
            VStack(spacing: 4) {
                Text(timeRemaining)
                    .font(.system(size: 36, weight: .medium, design: .monospaced))

                Text(state.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
            }
        }
        .padding(.vertical, 8)
    }

    private var stateColor: Color {
        Color(hex: state.color) ?? themeManager.currentTheme.accentColor
    }
}

// MARK: - Session Info Bar
struct SessionInfoBar: View {
    let completedSessions: Int
    let totalToday: Int
    let sessionsUntilLongBreak: Int

    var body: some View {
        HStack(spacing: 16) {
            // Progress to long break
            HStack(spacing: 4) {
                ForEach(0..<sessionsUntilLongBreak, id: \.self) { index in
                    Circle()
                        .fill(index < completedSessions ? Color.green : Color.primary.opacity(0.2))
                        .frame(width: 10, height: 10)
                }
            }

            Text("\(completedSessions)/\(sessionsUntilLongBreak) until long break")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Control Buttons
struct ControlButtons: View {
    let state: PomodoroState
    let onStart: () -> Void
    let onPause: () -> Void
    let onStop: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            // Stop button
            if state != .idle {
                Button(action: onStop) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                        .frame(width: 44, height: 44)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Stop")
            }

            // Main button (Start/Pause/Resume)
            Button(action: {
                if state == .idle || state == .paused {
                    onStart()
                } else {
                    onPause()
                }
            }) {
                Image(systemName: mainButtonIcon)
                    .font(.title)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(mainButtonColor)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .help(mainButtonHelp)

            // Skip button
            if state != .idle {
                Button(action: onSkip) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                        .frame(width: 44, height: 44)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Skip")
            }
        }
    }

    private var mainButtonIcon: String {
        switch state {
        case .idle, .paused:
            return "play.fill"
        default:
            return "pause.fill"
        }
    }

    private var mainButtonColor: Color {
        switch state {
        case .idle:
            return .green
        case .paused:
            return .orange
        case .working:
            return .red
        case .shortBreak, .longBreak:
            return .blue
        }
    }

    private var mainButtonHelp: String {
        switch state {
        case .idle:
            return "Start Focus Session"
        case .paused:
            return "Resume"
        default:
            return "Pause"
        }
    }
}

// MARK: - Today Stats
struct TodayStats: View {
    let focusTime: String
    let sessionsCompleted: Int

    var body: some View {
        HStack(spacing: 24) {
            StatItem(
                icon: "flame.fill",
                value: "\(sessionsCompleted)",
                label: "Sessions",
                color: .orange
            )

            StatItem(
                icon: "clock.fill",
                value: focusTime,
                label: "Focus Time",
                color: .blue
            )
        }
        .padding(.vertical, 8)
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Settings Sheet
struct PomodoroSettingsSheet: View {
    @Binding var settings: PomodoroSettings
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Timer Settings")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    onSave()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Durations
                    GroupBox("Durations") {
                        VStack(spacing: 12) {
                            DurationStepper(
                                label: "Focus Duration",
                                value: $settings.workDuration,
                                range: 1...60,
                                unit: "min"
                            )

                            DurationStepper(
                                label: "Short Break",
                                value: $settings.shortBreakDuration,
                                range: 1...30,
                                unit: "min"
                            )

                            DurationStepper(
                                label: "Long Break",
                                value: $settings.longBreakDuration,
                                range: 5...60,
                                unit: "min"
                            )

                            DurationStepper(
                                label: "Sessions until Long Break",
                                value: $settings.sessionsUntilLongBreak,
                                range: 2...8,
                                unit: ""
                            )
                        }
                        .padding(.vertical, 4)
                    }

                    // Auto-start
                    GroupBox("Automation") {
                        VStack(spacing: 8) {
                            Toggle("Auto-start breaks", isOn: $settings.autoStartBreaks)
                            Toggle("Auto-start work sessions", isOn: $settings.autoStartWork)
                        }
                        .padding(.vertical, 4)
                    }

                    // Notifications
                    GroupBox("Notifications") {
                        VStack(spacing: 8) {
                            Toggle("Show notifications", isOn: $settings.showNotifications)
                            Toggle("Play sound", isOn: $settings.playSound)
                        }
                        .padding(.vertical, 4)
                    }

                    // Presets
                    GroupBox("Quick Presets") {
                        HStack(spacing: 8) {
                            PresetButton(label: "Classic", work: 25, shortBreak: 5, longBreak: 15) {
                                settings.workDuration = 25
                                settings.shortBreakDuration = 5
                                settings.longBreakDuration = 15
                            }

                            PresetButton(label: "Short", work: 15, shortBreak: 3, longBreak: 10) {
                                settings.workDuration = 15
                                settings.shortBreakDuration = 3
                                settings.longBreakDuration = 10
                            }

                            PresetButton(label: "Long", work: 50, shortBreak: 10, longBreak: 30) {
                                settings.workDuration = 50
                                settings.shortBreakDuration = 10
                                settings.longBreakDuration = 30
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
            }
        }
        .frame(width: 340, height: 480)
    }
}

struct DurationStepper: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)

            Spacer()

            HStack(spacing: 8) {
                Button {
                    if value > range.lowerBound {
                        value -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(value <= range.lowerBound)

                Text("\(value)\(unit.isEmpty ? "" : " \(unit)")")
                    .font(.system(.subheadline, design: .monospaced))
                    .frame(minWidth: 50)

                Button {
                    if value < range.upperBound {
                        value += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .disabled(value >= range.upperBound)
            }
        }
    }
}

struct PresetButton: View {
    let label: String
    let work: Int
    let shortBreak: Int
    let longBreak: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                Text("\(work)/\(shortBreak)/\(longBreak)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PomodoroView()
        .frame(width: 380, height: 420)
}
