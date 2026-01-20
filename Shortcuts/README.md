# MomentumBar Focus Mode Shortcuts

This folder contains pre-made shortcuts that are automatically installed by MomentumBar to control macOS Focus modes.

## Available Shortcuts

### Required (Always Installed)
1. **MomentumBar-Do-Not-Disturb.shortcut** - Enables Do Not Disturb mode
2. **MomentumBar-Focus-Off.shortcut** - Disables all Focus modes

### Optional (User's Choice)
3. **MomentumBar-Work.shortcut** - Enables Work focus mode
4. **MomentumBar-Personal.shortcut** - Enables Personal focus mode
5. **MomentumBar-Sleep.shortcut** - Enables Sleep focus mode

**Note:** The app will auto-detect which Focus modes are configured on the user's Mac and install shortcuts for all of them.

## How to Create These Shortcuts

Since `.shortcut` files are binary and can't be created manually, follow these steps:

### Method 1: Create Shortcuts Manually (One-Time Setup)

#### 1. Create "MomentumBar Do Not Disturb" Shortcut

1. Open **Shortcuts** app (⌘+Space → type "Shortcuts")
2. Click the **+** button to create a new shortcut
3. Name it exactly: **`MomentumBar Do Not Disturb`**
4. Click **Add Action**
5. Search for and add: **"Set Focus"**
6. Configure the action:
   - Focus: **Do Not Disturb**
   - Duration: **Until Turned Off**
7. **Save** the shortcut

#### 2. Create "MomentumBar Work" Shortcut

1. Click the **+** button to create another shortcut
2. Name it exactly: **`MomentumBar Work`**
3. Click **Add Action**
4. Search for and add: **"Set Focus"**
5. Configure the action:
   - Focus: **Work**
   - Duration: **Until Turned Off**
6. **Save** the shortcut

#### 3. Create "MomentumBar Personal" Shortcut

1. Click the **+** button to create another shortcut
2. Name it exactly: **`MomentumBar Personal`**
3. Click **Add Action**
4. Search for and add: **"Set Focus"**
5. Configure the action:
   - Focus: **Personal**
   - Duration: **Until Turned Off**
6. **Save** the shortcut

#### 4. Create "MomentumBar Sleep" Shortcut

1. Click the **+** button to create another shortcut
2. Name it exactly: **`MomentumBar Sleep`**
3. Click **Add Action**
4. Search for and add: **"Set Focus"**
5. Configure the action:
   - Focus: **Sleep**
   - Duration: **Until Turned Off**
6. **Save** the shortcut

#### 5. Create "MomentumBar Focus Off" Shortcut

1. Click the **+** button to create another shortcut
2. Name it exactly: **`MomentumBar Focus Off`**
3. Click **Add Action**
4. Search for and add: **"Set Focus"**
5. Configure the action:
   - Turn Focus: **Off**
6. **Save** the shortcut

#### 6. Export Shortcuts for Distribution

1. Find your shortcuts in the Shortcuts app
2. **Right-click** each → **Export...**
3. Save as:
   - `MomentumBar-Do-Not-Disturb.shortcut`
   - `MomentumBar-Work.shortcut`
   - `MomentumBar-Personal.shortcut`
   - `MomentumBar-Sleep.shortcut`
   - `MomentumBar-Focus-Off.shortcut`
4. Move these files to this `Shortcuts/` folder
5. Commit and push to GitHub

### Method 2: Use These Pre-Built Shortcuts (Recommended)

If the shortcuts are already in this folder:

1. Double-click each `.shortcut` file
2. Click **"Add Shortcut"** in Shortcuts app
3. They'll be automatically imported

## How Auto-Installation Works

When users launch MomentumBar for the first time:

1. During onboarding, they'll see a "Focus Mode" step
2. Clicking "Install Focus Shortcuts" triggers `ShortcutInstaller.autoInstallShortcuts()`
3. The app uses the `shortcuts://import-shortcut?url=` URL scheme
4. Shortcuts are loaded from:
   ```
   https://raw.githubusercontent.com/YoussefAbdellaoui/Momentum-Bar/main/Shortcuts/MomentumBar-Do-Not-Disturb.shortcut
   https://raw.githubusercontent.com/YoussefAbdellaoui/Momentum-Bar/main/Shortcuts/MomentumBar-Focus-Off.shortcut
   ```
5. macOS Shortcuts app opens and prompts user to add each shortcut
6. User clicks "Add Shortcut" (once per shortcut)
7. Done! No manual configuration needed

## Fallback: Manual Setup

If auto-installation fails, users can manually create shortcuts using the instructions above.

## Testing Auto-Installation

```bash
# Reset installation state for testing
defaults delete com.momentumbar shortcutsInstalled

# Launch app and test onboarding
open MomentumBar.app
```

## Future Enhancements

- Support custom Focus modes (Work, Personal, Sleep, etc.)
- Detect user's existing Focus modes automatically
- Create shortcuts for each detected mode

## Troubleshooting

**Q: Shortcuts aren't installing automatically**
A: Make sure the files are committed to the main branch on GitHub and accessible via the raw.githubusercontent.com URL.

**Q: Getting 404 errors**
A: Check that the branch name is correct (main vs master) and files are pushed.

**Q: Shortcuts app doesn't open**
A: Check that the URL encoding is correct in `ShortcutInstaller.swift`.

## File Structure

```
Shortcuts/
├── README.md (this file)
├── MomentumBar-Do-Not-Disturb.shortcut (binary file)
└── MomentumBar-Focus-Off.shortcut (binary file)
```
