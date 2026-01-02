# Pomodoro Widget Implementation Plan

## Overview
Add a Pomodoro Timer widget to MomentumBar that displays timer state, progress, and allows basic control via interactive buttons.

---

## Current State Analysis

### Existing Pomodoro Implementation (`PomodoroService.swift`)
- **States**: `idle`, `working`, `shortBreak`, `longBreak`, `paused`
- **Tracked Data**:
  - `timeRemaining: TimeInterval`
  - `completedSessions: Int`
  - `totalSessionsToday: Int`
  - `state: PomodoroState`
  - `settings: PomodoroSettings`
- **Persistence Keys** (UserDefaults.standard):
  - `com.momentumbar.pomodoroSettings`
  - `com.momentumbar.pomodoroSessions`

### Current Storage Issue
- Main app uses `UserDefaults.standard` - not accessible to widget
- Need to sync to shared App Group: `group.com.momentumbar.shared`

---

## Implementation Steps

### Step 1: Create Shared Pomodoro State Model
**File**: Add to `StorageService.swift` (or create shared file)

```swift
struct SharedPomodoroState: Codable {
    let state: String          // PomodoroState raw value
    let timeRemaining: TimeInterval
    let totalDuration: TimeInterval
    let completedSessions: Int
    let totalSessionsToday: Int
    let sessionsUntilLongBreak: Int
    let lastUpdated: Date
    let endTime: Date?         // For widget timeline calculation
}
```

**App Group Keys**:
- `com.momentumbar.pomodoro.state`

---

### Step 2: Update PomodoroService to Sync to Widget
**File**: `MomentumBar/Features/Pomodoro/PomodoroService.swift`

Add method to sync state to App Group:
```swift
private func syncToWidget() {
    guard let sharedDefaults = UserDefaults(suiteName: "group.com.momentumbar.shared") else { return }

    let sharedState = SharedPomodoroState(
        state: state.rawValue,
        timeRemaining: timeRemaining,
        totalDuration: currentTotalDuration,
        completedSessions: completedSessions,
        totalSessionsToday: totalSessionsToday,
        sessionsUntilLongBreak: settings.sessionsUntilLongBreak,
        lastUpdated: Date(),
        endTime: calculateEndTime()
    )

    if let data = try? JSONEncoder().encode(sharedState) {
        sharedDefaults.set(data, forKey: "com.momentumbar.pomodoro.state")
    }

    WidgetCenter.shared.reloadTimelines(ofKind: "PomodoroWidget")
}
```

Call `syncToWidget()` in:
- `start()`
- `pause()`
- `resume()`
- `stop()`
- `skip()`
- `tick()` (every second when active)

---

### Step 3: Create Pomodoro Widget Views
**File**: `MomentumBarWidget/PomodoroWidget.swift`

#### Small Widget
- Circular progress ring
- Time remaining (large, centered)
- State label (Focus/Break/Paused)
- Color-coded by state

#### Medium Widget
- Circular progress ring (left side)
- Time remaining + state
- Session progress dots (X/4 until long break)
- Today's stats: sessions completed, focus time

#### Large Widget
- All of above
- Control buttons (Start/Pause/Stop) via App Intents
- Detailed today stats

---

### Step 4: Create Widget Timeline Provider
**File**: `MomentumBarWidget/PomodoroWidget.swift`

```swift
struct PomodoroProvider: TimelineProvider {
    func timeline(in context: Context) -> Timeline<PomodoroEntry> {
        // Load shared state from App Group
        // If timer is running, generate entries for each second until completion
        // Use .atEnd policy to refresh when timer completes
    }
}
```

Timeline strategy:
- **Idle/Paused**: Single entry, refresh after 15 minutes
- **Running**: Generate entries every second for next 60 seconds, then refresh

---

### Step 5: Add Interactive Controls (App Intents)
**File**: `MomentumBarWidget/PomodoroWidget.swift`

```swift
struct StartPomodoroIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Pomodoro"

    func perform() async throws -> some IntentResult {
        // Send notification to main app via App Group flag
        // Main app observes this and starts timer
    }
}

struct PausePomodoroIntent: AppIntent { ... }
struct StopPomodoroIntent: AppIntent { ... }
```

**Note**: Widget intents can only write to App Group. Main app needs to observe changes and respond.

---

### Step 6: Update Main App to Listen for Widget Commands
**File**: `MomentumBar/Features/Pomodoro/PomodoroService.swift`

Add observer for widget commands:
```swift
private func setupWidgetCommandObserver() {
    // Check App Group for pending commands on app activation
    // Or use Darwin notifications for real-time communication
}
```

**App Group Command Keys**:
- `com.momentumbar.pomodoro.command` (start/pause/stop)
- `com.momentumbar.pomodoro.commandTimestamp`

---

### Step 7: Register Widget in Widget Bundle
**File**: `MomentumBarWidget/MomentumBarWidget.swift`

Update the `@main` widget bundle to include both widgets:
```swift
@main
struct MomentumBarWidgetBundle: WidgetBundle {
    var body: some Widget {
        MomentumBarWidget()      // Existing timezone widget
        PomodoroWidget()         // New pomodoro widget
    }
}
```

---

## File Changes Summary

| File | Action |
|------|--------|
| `StorageService.swift` | Add `SharedPomodoroState` model and sync keys |
| `PomodoroService.swift` | Add `syncToWidget()` and widget command observer |
| `MomentumBarWidget.swift` | Update to WidgetBundle with both widgets |
| `PomodoroWidget.swift` | **NEW** - Widget views, provider, intents |

---

## Widget Design Specs

### Colors by State
| State | Color |
|-------|-------|
| Idle | Gray (#8E8E93) |
| Working/Focus | Red (#FF3B30) |
| Short Break | Green (#34C759) |
| Long Break | Blue (#007AFF) |
| Paused | Orange (#FF9500) |

### Small Widget Layout
```
┌─────────────────┐
│    ╭─────╮      │
│   ╱  ●●●  ╲     │  ← Progress ring
│  │  25:00  │    │  ← Time
│   ╲       ╱     │
│    ╰─────╯      │
│     FOCUS       │  ← State label
└─────────────────┘
```

### Medium Widget Layout
```
┌─────────────────────────────────────┐
│  ╭─────╮  │  FOCUS SESSION          │
│ ╱  ●●●  ╲ │  25:00                  │
│ │       │ │  ●●●○ until long break  │
│ ╲       ╱ │─────────────────────────│
│  ╰─────╯  │  🔥 3 sessions  ⏱ 1h 25m│
└─────────────────────────────────────┘
```

---

## Execution Order

1. [ ] Add `SharedPomodoroState` to `StorageService.swift`
2. [ ] Add sync keys for pomodoro to `StorageService.Keys`
3. [ ] Update `PomodoroService.swift` with `syncToWidget()` method
4. [ ] Call `syncToWidget()` at all state change points
5. [ ] Create `PomodoroWidget.swift` with:
   - Entry model
   - Timeline provider
   - Small widget view
   - Medium widget view
   - Large widget view
   - App Intents for controls
6. [ ] Update `MomentumBarWidget.swift` to use WidgetBundle
7. [ ] Add widget command observer to `PomodoroService`
8. [ ] Test widget displays and updates correctly

---

## Notes

- Widget timelines update every second when timer is running (performance consideration)
- For better battery, consider updating every 5 seconds instead
- App Intents require iOS 17+ / macOS 14+ for interactive widgets
- Main app must be running (or launched) for controls to work properly
