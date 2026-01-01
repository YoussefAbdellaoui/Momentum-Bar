# Swift macOS Menu Bar App: Time Zone & Calendar Manager
## Comprehensive Development Prompt

You are a Swift engineer tasked with building a native macOS menu bar application similar to "Time" - a time zone and calendar manager widget. This is a high-performance, privacy-first application with a one-time purchase model.

## PROJECT OVERVIEW

**Application Name:** Momentum Bar
**Platform:** macOS (Sonoma 14+, optimized for macOS 26+)
**UI Framework:** SwiftUI
**Architecture:** Native SwiftUI with minimal external dependencies
**Distribution Model:** One-time purchase (no subscriptions)
**Target Users:** Remote teams, international businesses, scheduling professionals

## CORE FEATURES TO IMPLEMENT

### 1. TIME ZONE MANAGEMENT

**Multi-Time Zone Display:**
- Allow users to add unlimited time zones to the menu bar
- Display time zones in a compact menu bar popup
- Store user-selected time zones in UserDefaults or similar persistent storage
- Integrate with system TimeZone API

**City Search & Autocomplete:**
- Implement intelligent autocomplete for city/timezone search
- Use Foundation's TimeZone identifier database
- Filter results in real-time as user types
- Show timezone offset in search results
- Support both city names and timezone identifiers (e.g., "America/New_York", "PST")

**Custom Naming:**
- Allow users to rename any timezone with custom labels (e.g., "Mom", "Tokyo Office", "Client PST")
- Store custom names in user preferences
- Display custom names in menu bar and full interface

**Drag-to-Reorder:**
- Implement drag-and-drop reordering of time zones
- Support keyboard shortcut: ⌘ + drag to reorder
- Persist new order to storage

### 2. DISPLAY CUSTOMIZATION

**Format Options:**
- Support both 12-hour and 24-hour time formats
- Option to show/hide seconds
- Custom separator options (colon, dot, etc.)
- Configurable font weights (light, regular, bold)
- Font family selection
- Text alignment options (left, center, right)

**Color Customization:**
- Per-timezone color picker
- Preset color schemes
- Dark/light mode awareness
- Color customization for day/night indicators

**Display Modes:**
1. Show full city names (e.g., "Tokyo: 3:45 PM")
2. Show timezone abbreviations (e.g., "JST: 3:45 PM")
3. Show UTC offsets (e.g., "+09:00: 3:45 PM")
4. Combination mode user can customize

### 3. DAY & NIGHT AWARENESS

**Visual Time Indicators:**
- Color-code each timezone segment to show daylight/nighttime
- Light color for daytime (approximately 6 AM - 6 PM)
- Dark color for nighttime
- Use Sunrise/Sunset calculation for accuracy
- Calculate sunrise/sunset using user's system location or manual location setting

**Awake Status Display:**
- Show visual indicator of who's awake/asleep
- Display summary: "3 awake, 2 asleep"
- Tooltip showing individual timezone sleep status

### 4. CALENDAR INTEGRATION

**Calendar Access:**
- Request and handle calendar access permissions
- Support multiple calendar selection (user chooses which to monitor)
- Filter to exclude calendar noise
- Use EventKit framework

**Meeting Detection:**
- Automatically detect and parse meeting links from event descriptions
- Support: Zoom, Google Meet, Microsoft Teams meeting links
- Extract URLs using regex patterns or string parsing
- Create clickable buttons for one-click join

**Event Display:**
- Show upcoming events (next 24 hours)
- Show recent events (last 2 hours)
- Display event title and time
- Progress bar for ongoing meetings
- Color-code based on meeting platform

**Meeting Alerts:**
- Configurable notification timing (default: 10 minutes before)
- Dismiss/snooze options
- Integrate with macOS Notification Center
- Badge showing upcoming meeting count in menu bar

**One-Click Join:**
- Detect meeting link in event
- "Join" button opens meeting URL in default browser
- Support deep links for Zoom (zoommtg://) and Teams (msteams://)

### 5. TIME SCROLLER (TIME TRAVEL)

**Interactive Time Slider:**
- Horizontal slider/scroller to preview times in past/future
- Range: -24 hours to +24 hours from current time
- Smooth, real-time updates across all timezones
- Visual feedback showing time progression

**Dual Visualization:**
- Show current time in all zones
- Show preview time in all zones below/beside
- Color-coded day/night segments for preview time
- Timeline visualization showing 24-hour span

**Optimal Meeting Time Detection:**
- Highlight time windows where everyone is awake
- Visual indicators showing overlap zones
- Tooltip suggestions: "Perfect meeting time: 2-3 PM UTC"

### 6. MENU BAR INTEGRATION

**Menu Bar Presence:**
- Minimal menu bar icon with time display
- Icon colors reflect day/night status
- Text updates in real-time (every second)
- Configurable text size and font

**Popup Window:**
- Click menu bar icon to open floating popup
- Show all configured timezones
- Display compact event list
- Clean, minimal UI
- Support keyboard shortcuts to launch/close

**System Integration:**
- Launch at login option
- Hide/show dock icon option
- Menu bar only mode
- System preferences/settings window

### 7. PERFORMANCE & OPTIMIZATION

**Native SwiftUI Performance:**
- Use @State, @StateObject for efficient state management
- Debounce real-time updates (update every second, not every millisecond)
- Lazy load calendar data
- Cache timezone calculations
- Minimize CPU usage when app is in background

**Resource Efficiency:**
- Memory footprint under 50MB
- CPU usage under 1% when idle
- Efficient timer for second-by-second updates
- Background task management

### 8. PRIVACY & DATA

**Privacy First:**
- No analytics or user tracking
- No data sent to external servers
- Local storage only (UserDefaults or local database)
- Calendar access only with explicit user permission
- Transparent about permissions

**Data Storage:**
- Store preferences in UserDefaults or Codable + FileManager
- User data never leaves device
- Support backup/export of settings

## TECHNICAL SPECIFICATIONS

### Architecture
- **Main App Structure:** NSApplication with menu bar StatusItem
- **UI Layer:** SwiftUI for all interfaces
- **Data Layer:** Combine for reactive data flow
- **State Management:** @StateObject, @ObservedObject
- **Persistence:** UserDefaults + Codable structs

### File Structure
```
TimeZoneApp/
├── App/
│   ├── TimeZoneApp.swift (main entry point)
│   ├── AppDelegate.swift (menu bar setup)
│   └── MenuBarManager.swift (menu bar icon/popup)
├── Features/
│   ├── TimeZones/
│   │   ├── TimeZoneViewModel.swift
│   │   ├── TimeZoneView.swift
│   │   └── TimeZoneService.swift
│   ├── Calendar/
│   │   ├── CalendarViewModel.swift
│   │   ├── CalendarView.swift
│   │   └── CalendarService.swift (EventKit integration)
│   ├── TimeScroller/
│   │   ├── TimeScrollerView.swift
│   │   └── TimeScrollerViewModel.swift
│   └── Settings/
│       ├── SettingsView.swift
│       └── PreferencesService.swift
├── Models/
│   ├── TimeZoneModel.swift
│   ├── EventModel.swift
│   └── PreferencesModel.swift
├── Services/
│   ├── TimeService.swift (time calculations)
│   ├── SunriseSunsetService.swift (day/night detection)
│   ├── MeetingLinkParser.swift (Zoom/Teams/Meet detection)
│   └── StorageService.swift (UserDefaults wrapper)
└── Utilities/
    ├── DateFormatters.swift
    ├── Constants.swift
    └── Extensions.swift
```

### Key Technologies
- **Foundation:** TimeZone, Calendar, Date
- **EventKit:** Calendar access and event parsing
- **SwiftUI:** All UI components
- **Combine:** Reactive programming (optional)
- **AppKit:** NSStatusBar, NSPopover for menu bar
- **CoreLocation:** Optional - for sunrise/sunset calculations

### Development Workflow
1. Set up basic menu bar app structure
2. Implement timezone storage and display
3. Build settings window
4. Add calendar integration
5. Implement time scroller
6. Polish UI and optimize performance
7. Add preferences and customization
8. Testing and bug fixes

## UI/UX GUIDELINES

### Menu Bar
- Keep text minimal and readable (max 50 characters)
- Use monospace font for time alignment
- Update smoothly every second
- Support custom font sizes (small, medium, large)

### Main Popup Window
- Width: 400-500px
- Height: Scalable based on content
- Rounded corners with subtle shadow
- Blur background effect (optional)
- Light and dark mode support

### Settings Window
- Organized tabs: "Timezones", "Calendar", "Display", "About"
- Clear toggle switches for options
- Color pickers with presets
- Drag-and-drop visual feedback
- Real-time preview of changes

## TESTING REQUIREMENTS

- Unit tests for timezone calculations
- Unit tests for time formatting
- Integration tests for calendar access
- Visual tests for menu bar rendering
- Performance benchmarks
- Test across multiple timezone configurations
- Verify calendar link detection for all 3 platforms (Zoom, Meet, Teams)

## DELIVERABLES

1. Fully functional macOS app (arm64 + x86_64 support)
2. Code documentation and comments
3. Settings persistence across app restarts
4. Menu bar integration working smoothly
5. All features functional and tested
6. App signing/notarization ready

## CONSTRAINTS & NOTES

- **Require macOS 14 Sonoma minimum** (use availability annotations for newer features)
- **Code must be maintainable** - use MVVM or clean architecture
- **Minimize external dependencies** - prefer native APIs
- **Performance critical** - must not impact system performance
- **Privacy by default** - no data collection, no analytics
- **One-time purchase** - no subscription logic needed (handle via external payment processor)

## SUCCESS CRITERIA

✓ All core features implemented and working
✓ App launches at startup (user opt-in)
✓ Menu bar updates in real-time
✓ Calendar integration functional with proper permissions
✓ Meeting links detected and clickable
✓ Time zone calculations accurate
✓ App uses <50MB memory
✓ Runs smoothly with <1% CPU idle
✓ Supports light/dark mode
✓ Settings persist across restarts
✓ No external data transmission
✓ Keyboard shortcuts functional
✓ Clean, professional UI

## BONUS FEATURES (OPTIONAL)

- Keyboard shortcuts for quick timezone conversion
- World clock visualization
- Sunrise/sunset times display
- International holidays calendar
- Custom timezone groups (work, personal, etc.)
- Export timezone configuration
- Theme customization beyond light/dark
- Meeting history and statistics
- Integration with calendar suggestions for best meeting times

***
