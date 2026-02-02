# Ready to Deploy - Action Plan

## 🎯 Current Status

✅ **Code is ready:**
- Deployment target fixed (14.0)
- Hide dock icon by default
- Multi Focus mode support implemented
- Auto-installation feature ready
- Backend code ready

⚠️ **You need to complete these steps before deployment:**

---

## 📋 Step-by-Step Deployment Guide

### TODAY: Create Focus Mode Shortcuts (15-30 minutes)

This is the **only** thing blocking deployment of the Focus Mode feature.

#### Step 1: Open Shortcuts App

```bash
# Open Shortcuts app
open -a Shortcuts
```

Or: Press `⌘ + Space` → type "Shortcuts" → Enter

#### Step 2: Create Each Shortcut

Create these 5 shortcuts **exactly** as shown:

---

**Shortcut 1 of 5: MomentumBar Do Not Disturb**

1. Click the **+** button (top right)
2. In the name field at top, type: `MomentumBar Do Not Disturb`
3. Click **Add Action**
4. Search for: `Set Focus`
5. Click **"Set Focus"** to add it
6. In the action:
   - Click "Focus" dropdown → Select **"Do Not Disturb"**
   - Click "for" dropdown → Select **"Until Turned Off"**
7. Click **Done** (top right)

✅ Shortcut 1 created

---

**Shortcut 2 of 5: MomentumBar Work**

1. Click **+** button
2. Name: `MomentumBar Work`
3. Click **Add Action**
4. Search for: `Set Focus`
5. Add **"Set Focus"** action
6. Configure:
   - Focus → **"Work"**
   - Duration → **"Until Turned Off"**
7. Click **Done**

✅ Shortcut 2 created

---

**Shortcut 3 of 5: MomentumBar Personal**

1. Click **+** button
2. Name: `MomentumBar Personal`
3. Click **Add Action**
4. Search for: `Set Focus`
5. Add **"Set Focus"** action
6. Configure:
   - Focus → **"Personal"**
   - Duration → **"Until Turned Off"**
7. Click **Done**

✅ Shortcut 3 created

---

**Shortcut 4 of 5: MomentumBar Sleep**

1. Click **+** button
2. Name: `MomentumBar Sleep`
3. Click **Add Action**
4. Search for: `Set Focus`
5. Add **"Set Focus"** action
6. Configure:
   - Focus → **"Sleep"**
   - Duration → **"Until Turned Off"**
7. Click **Done**

✅ Shortcut 4 created

---

**Shortcut 5 of 5: MomentumBar Focus Off**

1. Click **+** button
2. Name: `MomentumBar Focus Off`
3. Click **Add Action**
4. Search for: `Set Focus`
5. Add **"Set Focus"** action
6. Configure:
   - Click the toggle → Select **"Turns off focus"**
7. Click **Done**

✅ Shortcut 5 created

---

#### Step 3: Export All Shortcuts

Now export each shortcut to the Shortcuts folder:

1. Find **"MomentumBar Do Not Disturb"** in the shortcuts list
2. **Right-click** → **"Export..."**
3. Navigate to: `/Users/youssefabdellaoui/Developer/Github/Momentum-Bar/Shortcuts`
4. Save as: `MomentumBar-Do-Not-Disturb.shortcut`

Repeat for each shortcut:
- ✅ MomentumBar Do Not Disturb → `MomentumBar-Do-Not-Disturb.shortcut`
- ✅ MomentumBar Work → `MomentumBar-Work.shortcut`
- ✅ MomentumBar Personal → `MomentumBar-Personal.shortcut`
- ✅ MomentumBar Sleep → `MomentumBar-Sleep.shortcut`
- ✅ MomentumBar Focus Off → `MomentumBar-Focus-Off.shortcut`

#### Step 4: Verify Files Exist

```bash
# Check all shortcuts were exported
ls -lh Shortcuts/*.shortcut

# Should show 5 files:
# MomentumBar-Do-Not-Disturb.shortcut
# MomentumBar-Work.shortcut
# MomentumBar-Personal.shortcut
# MomentumBar-Sleep.shortcut
# MomentumBar-Focus-Off.shortcut
```

#### Step 5: Commit to GitHub

```bash
# Add shortcuts
git add Shortcuts/*.shortcut

# Add all other changes
git add .

# Commit
git commit -m "Add multi Focus mode support with auto-installation shortcuts"

# Push
git push origin main
```

#### Step 6: Verify URLs Work

Wait 1-2 minutes for GitHub to process, then test:

```bash
# Test each URL (should return HTTP/2 200)
curl -I "https://raw.githubusercontent.com/YoussefAbdellaoui/Momentum-Bar/main/Shortcuts/MomentumBar-Do-Not-Disturb.shortcut"

curl -I "https://raw.githubusercontent.com/YoussefAbdellaoui/Momentum-Bar/main/Shortcuts/MomentumBar-Work.shortcut"

curl -I "https://raw.githubusercontent.com/YoussefAbdellaoui/Momentum-Bar/main/Shortcuts/MomentumBar-Personal.shortcut"

curl -I "https://raw.githubusercontent.com/YoussefAbdellaoui/Momentum-Bar/main/Shortcuts/MomentumBar-Sleep.shortcut"

curl -I "https://raw.githubusercontent.com/YoussefAbdellaoui/Momentum-Bar/main/Shortcuts/MomentumBar-Focus-Off.shortcut"
```

All should return: `HTTP/2 200`

---

### NEXT: Follow Deployment Checklist

Once shortcuts are created and pushed, follow:

```bash
# Open deployment checklist
open DEPLOYMENT_CHECKLIST.md
```

## 🎯 Remaining Deployment Tasks

After shortcuts are done, you still need to:

### Phase 1: App Assets
- [ ] Create app icons (10 PNG files)
- [ ] Sign up for Apple Developer account ($99)

### Phase 2: Backend
- [ ] Deploy backend to Railway
- [ ] Configure Dodo Payments
- [ ] Configure Resend email

### Phase 3: Build & Sign
- [ ] Build release version in Xcode
- [ ] Code sign with Developer ID
- [ ] Notarize with Apple

### Phase 4: Distribute
- [ ] Create DMG installer
- [ ] Upload to GitHub Releases
- [ ] Update website with download link

**Estimated Total Time:** 2-3 days
- Day 1: Shortcuts (30 min) + App icons (2 hours) + Apple Developer signup
- Day 2: Backend deployment (4 hours) + Wait for Apple approval
- Day 3: Build, sign, notarize, create DMG (4 hours)

---

## 🧪 Quick Test After Shortcuts

Want to test the auto-installation feature right now?

```bash
# 1. Reset installation state
defaults delete com.momentumbar shortcutsInstalled

# 2. Build and run in Xcode
open MomentumBar.xcodeproj

# 3. In Xcode:
# - Product → Run (⌘+R)
# - Go through onboarding to Focus Mode step
# - Click "Auto-Install Focus Shortcuts"
# - Verify Shortcuts app opens for each mode
# - Click "Add Shortcut" for each one

# 4. Verify installation
shortcuts list | grep "MomentumBar"

# Should show:
# MomentumBar Do Not Disturb
# MomentumBar Work
# MomentumBar Personal
# MomentumBar Sleep
# MomentumBar Focus Off
```

---

## 📞 Need Help?

If you get stuck:

### Issue: "Can't find Focus mode in dropdown"

**Solution:** You need to enable these Focus modes in System Settings first:
1. System Settings → Focus
2. Click **+** → Add Work, Personal, Sleep
3. Relaunch MomentumBar

### Issue: "Export doesn't show Shortcuts folder"

**Solution:**
```bash
# Open Shortcuts folder in Finder
open Shortcuts/

# Then when exporting, use ⌘+Shift+G to "Go to Folder"
# Paste: /Users/youssefabdellaoui/Developer/Github/Momentum-Bar/Shortcuts
```

### Issue: "URLs return 404"

**Solution:**
- Wait 1-2 minutes after pushing
- Verify branch name is "main" (not "master")
- Check files are actually in GitHub web interface

---

## 🎉 Once Shortcuts Are Done

You'll have completed:
- ✅ All code changes
- ✅ Focus Mode auto-installation feature
- ✅ Multi-mode support
- ✅ All shortcuts hosted on GitHub

**The hardest technical part is done!**

The remaining steps (app icons, Apple account, backend) are more administrative than technical.

---

## 📝 Summary

**Today (30 minutes):**
1. Create 5 shortcuts in Shortcuts app
2. Export them to Shortcuts/ folder
3. Commit and push to GitHub
4. Verify URLs work

**After that:**
- Follow DEPLOYMENT_CHECKLIST.md for remaining steps
- Most time will be waiting for Apple Developer approval (24-48 hours)
- Actual work is ~1-2 days spread across a week

**You're almost there!** 🚀

---

**Ready to start?** Open Shortcuts app and create the first shortcut: "MomentumBar Do Not Disturb"
