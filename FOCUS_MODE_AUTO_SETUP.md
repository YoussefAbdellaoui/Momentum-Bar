# Focus Mode Auto-Setup Implementation

## Overview

The app now **automatically installs Focus Mode shortcuts** with minimal user interaction. Users just click one button during onboarding, and the shortcuts are installed automatically.

## What Changed

### Before (Manual Setup)
- Users had to manually create 2 shortcuts in the Shortcuts app
- Required following 6-step instructions for each shortcut
- Error-prone (typos in naming, wrong settings)
- Time-consuming (~5 minutes)

### After (Automatic Setup)
- Users click "Install Focus Shortcuts" during onboarding
- Shortcuts app opens automatically for each shortcut
- User just clicks "Add Shortcut" (once per shortcut)
- Takes ~30 seconds total
- No manual configuration needed

## How It Works

### 1. New Service: `ShortcutInstaller`

**File:** `MomentumBar/Services/ShortcutInstaller.swift`

This service:
- Manages automatic shortcut installation
- Hosts shortcuts on GitHub (via raw.githubusercontent.com)
- Uses `shortcuts://import-shortcut?url=` URL scheme
- Tracks installation state to avoid re-importing
- Provides fallback to manual setup if needed

**Key Methods:**
```swift
// Auto-install all required shortcuts
func autoInstallShortcuts() async -> Bool

// Check if shortcuts are installed
var hasInstalledShortcuts: Bool

// Verify installation
func verifyInstallation() -> Bool

// Reset for testing
func resetInstallationState()
```

### 2. Updated Onboarding Flow

**File:** `MomentumBar/Features/Onboarding/OnboardingView.swift`

Changes:
- Added `ShortcutInstaller.shared` state
- Focus Mode step now shows "Install Focus Shortcuts" button
- Button triggers auto-installation
- Shows progress: "Installing..." during installation
- Status indicator shows "Focus shortcuts installed" when done

**User Experience:**
1. User reaches "Focus Mode" step in onboarding
2. Clicks "Install Focus Shortcuts"
3. Shortcuts app opens for each shortcut
4. User clicks "Add Shortcut" (automated by macOS)
5. Returns to MomentumBar - setup complete!

### 3. Shortcut Files

**Location:** `Shortcuts/` folder

Required files:
- `MomentumBar-Do-Not-Disturb.shortcut` - Enables Do Not Disturb
- `MomentumBar-Focus-Off.shortcut` - Disables Focus Mode

These are binary `.shortcut` files created in the Shortcuts app and committed to the repo.

## Setup Instructions (One-Time for You)

Before deployment, you need to create and commit the shortcut files:

### Step 1: Create Shortcuts

```bash
# Run the helper script for instructions
cd Shortcuts
./create-shortcuts.sh
```

Or manually:

1. Open **Shortcuts** app
2. Create **"MomentumBar Do Not Disturb"** shortcut:
   - Click **+** (new shortcut)
   - Name: `MomentumBar Do Not Disturb`
   - Add action: **"Set Focus"**
   - Focus: **Do Not Disturb**
   - Duration: **Until Turned Off**
   - Save

3. Create **"MomentumBar Focus Off"** shortcut:
   - Click **+** (new shortcut)
   - Name: `MomentumBar Focus Off`
   - Add action: **"Set Focus"**
   - Turn Focus: **Off**
   - Save

### Step 2: Export Shortcuts

1. **Right-click** each shortcut → **Export...**
2. Save to `Shortcuts/` folder:
   - `MomentumBar-Do-Not-Disturb.shortcut`
   - `MomentumBar-Focus-Off.shortcut`

### Step 3: Commit to GitHub

```bash
git add Shortcuts/*.shortcut
git commit -m "Add pre-built Focus Mode shortcuts for auto-installation"
git push origin main
```

### Step 4: Verify URLs Work

After pushing, verify the shortcuts are accessible:

```bash
# Should return 200 OK
curl -I "https://raw.githubusercontent.com/YoussefAbdellaoui/Momentum-Bar/main/Shortcuts/MomentumBar-Do-Not-Disturb.shortcut"

curl -I "https://raw.githubusercontent.com/YoussefAbdellaoui/Momentum-Bar/main/Shortcuts/MomentumBar-Focus-Off.shortcut"
```

## Testing

### Test Auto-Installation

1. **Reset installation state:**
   ```bash
   defaults delete com.momentumbar shortcutsInstalled
   ```

2. **Delete test shortcuts** (if they exist):
   - Open Shortcuts app
   - Delete "MomentumBar Do Not Disturb"
   - Delete "MomentumBar Focus Off"

3. **Launch app:**
   ```bash
   open build/MomentumBar.app
   ```

4. **Go through onboarding:**
   - Navigate to "Focus Mode" step
   - Click "Install Focus Shortcuts"
   - Verify Shortcuts app opens
   - Click "Add Shortcut" for each one
   - Verify status shows "Focus shortcuts installed"

5. **Test shortcuts work:**
   - Open Shortcuts app
   - Run "MomentumBar Do Not Disturb"
   - Verify Do Not Disturb enables (moon icon in menu bar)
   - Run "MomentumBar Focus Off"
   - Verify Do Not Disturb disables

6. **Test from MomentumBar:**
   - Start a Pomodoro session
   - Verify Focus Mode automatically enables
   - Finish Pomodoro
   - Verify Focus Mode automatically disables

## Technical Details

### URL Scheme

The app uses macOS's built-in shortcuts import scheme:

```
shortcuts://import-shortcut?url=<encoded-url>&name=<shortcut-name>
```

Example:
```
shortcuts://import-shortcut?url=https%3A%2F%2Fraw.githubusercontent.com%2FYoussefAbdellaoui%2FMomentum-Bar%2Fmain%2FShortcuts%2FMomentumBar-Do-Not-Disturb.shortcut&name=MomentumBar%20Do%20Not%20Disturb
```

### Hosting via GitHub

The shortcuts are hosted on GitHub's raw content CDN:
- Free
- Fast (CDN-backed)
- Reliable
- No additional hosting needed

### Security

- Shortcuts are sandboxed by macOS
- Only can control Focus Mode (limited scope)
- User must approve each shortcut installation
- No access to sensitive data

### Limitations

- Requires macOS 12 (Monterey) or later for Shortcuts support
- User must click "Add Shortcut" for each one (macOS security requirement)
- Can't programmatically create shortcuts without this step
- Shortcuts must be created once and committed to repo

## Fallback Strategy

If auto-installation fails:

1. App shows manual setup instructions
2. Opens Shortcuts app
3. User creates shortcuts manually (original flow)
4. Backward compatible

## Future Enhancements

### 1. Support Custom Focus Modes

Detect user's existing Focus modes:
```swift
// Read from ~/Library/DoNotDisturb/DB/ModeConfigurations.json
// Create shortcuts for: Work, Personal, Sleep, Gaming, etc.
```

### 2. One-Click Installation

Explore using:
- `shortcuts import --file` CLI command
- Embedding shortcuts in app bundle
- Direct file system manipulation (requires elevated permissions)

### 3. Smart Focus Mode Selection

Let users choose which Focus mode to use:
- During Pomodoro: Work mode
- During meetings: Do Not Disturb
- After hours: Personal mode

## Files Modified

1. **NEW:** `MomentumBar/Services/ShortcutInstaller.swift`
   - Automatic shortcut installation service

2. **UPDATED:** `MomentumBar/Features/Onboarding/OnboardingView.swift`
   - Added auto-install button
   - Updated Focus Mode step
   - Progress indicators

3. **UPDATED:** `MomentumBar/Models/AppPreferences.swift`
   - Changed `hideDockIcon` default to `true`

4. **NEW:** `Shortcuts/README.md`
   - Documentation for shortcuts

5. **NEW:** `Shortcuts/create-shortcuts.sh`
   - Helper script for creating shortcuts

6. **NEW:** `FOCUS_MODE_AUTO_SETUP.md` (this file)
   - Implementation guide

## Benefits

✅ **Better UX:** One-click installation vs manual 6-step process
✅ **Fewer errors:** No typos, wrong settings, or missing steps
✅ **Faster onboarding:** 30 seconds vs 5 minutes
✅ **Professional:** Feels polished and automated
✅ **Maintainable:** Shortcuts are version-controlled
✅ **Scalable:** Easy to add more shortcuts in future

## Deployment Checklist Addition

Before deploying v1.0:

- [ ] Create Focus Mode shortcuts in Shortcuts app
- [ ] Export shortcuts to `Shortcuts/` folder
- [ ] Commit shortcuts to GitHub
- [ ] Verify URLs are accessible
- [ ] Test auto-installation flow
- [ ] Test shortcuts actually control Focus Mode
- [ ] Update onboarding screenshots (if any)

---

**Status:** ✅ Implemented
**Version:** 1.0.0
**Last Updated:** 2026-01-20
