# MomentumBar Deployment Checklist
## Direct Distribution (No App Store)

**Target Launch Date:** _____________
**Current Version:** 1.0.0
**Distribution Method:** Direct download from website

---

## ✅ Pre-Deployment Fixes Completed

- [x] **Fixed deployment target** (26.2 → 14.0) - macOS Sonoma minimum
- [x] **Fixed hide dock icon default** (false → true) - App will hide from dock by default
- [x] **Added multi Focus mode support** - Works with Do Not Disturb, Work, Personal, Sleep, and custom modes

---

## 📋 Phase 0: Focus Mode Shortcuts Setup (DO THIS FIRST!)

### 0. 🌙 Create Focus Mode Shortcuts
**Status:** ❌ NOT STARTED
**Priority:** CRITICAL (blocks auto-installation feature)
**Timeline:** 15-30 minutes
**See:** `FOCUS_MODES_SUMMARY.md` for details

The app auto-installs Focus Mode shortcuts during onboarding. You need to create and host these shortcuts first.

#### Required Shortcuts (Must Create)

**Method 1: Use Helper Script (Recommended)**
```bash
cd Shortcuts
./create-shortcuts.sh
# Follow the instructions to create each shortcut
```

**Method 2: Manual Creation**

Open **Shortcuts** app (⌘+Space → "Shortcuts") and create these 5 shortcuts:

**A. MomentumBar Do Not Disturb**
- [ ] Click **+** (new shortcut)
- [ ] Name: `MomentumBar Do Not Disturb` (exact spelling!)
- [ ] Add action: **"Set Focus"**
- [ ] Configure: Focus → **Do Not Disturb**, Duration → **Until Turned Off**
- [ ] Save

**B. MomentumBar Work**
- [ ] Click **+**
- [ ] Name: `MomentumBar Work`
- [ ] Add action: **"Set Focus"**
- [ ] Configure: Focus → **Work**, Duration → **Until Turned Off**
- [ ] Save

**C. MomentumBar Personal**
- [ ] Click **+**
- [ ] Name: `MomentumBar Personal`
- [ ] Add action: **"Set Focus"**
- [ ] Configure: Focus → **Personal**, Duration → **Until Turned Off**
- [ ] Save

**D. MomentumBar Sleep**
- [ ] Click **+**
- [ ] Name: `MomentumBar Sleep`
- [ ] Add action: **"Set Focus"**
- [ ] Configure: Focus → **Sleep**, Duration → **Until Turned Off**
- [ ] Save

**E. MomentumBar Focus Off**
- [ ] Click **+**
- [ ] Name: `MomentumBar Focus Off`
- [ ] Add action: **"Set Focus"**
- [ ] Configure: Turn Focus → **Off**
- [ ] Save

#### Export Shortcuts

- [ ] **Right-click** "MomentumBar Do Not Disturb" → **Export** → Save as `MomentumBar-Do-Not-Disturb.shortcut`
- [ ] **Right-click** "MomentumBar Work" → **Export** → Save as `MomentumBar-Work.shortcut`
- [ ] **Right-click** "MomentumBar Personal" → **Export** → Save as `MomentumBar-Personal.shortcut`
- [ ] **Right-click** "MomentumBar Sleep" → **Export** → Save as `MomentumBar-Sleep.shortcut`
- [ ] **Right-click** "MomentumBar Focus Off" → **Export** → Save as `MomentumBar-Focus-Off.shortcut`
- [ ] Move all 5 files to `Shortcuts/` folder

#### Commit to GitHub

```bash
git add Shortcuts/*.shortcut
git commit -m "Add Focus Mode shortcuts (DND, Work, Personal, Sleep)"
git push origin main
```

#### Verify URLs Are Accessible

After pushing, verify each shortcut is accessible:

```bash
# All should return: HTTP/2 200
curl -I "https://raw.githubusercontent.com/YoussefAbdellaoui/Momentum-Bar/main/Shortcuts/MomentumBar-Do-Not-Disturb.shortcut"
curl -I "https://raw.githubusercontent.com/YoussefAbdellaoui/Momentum-Bar/main/Shortcuts/MomentumBar-Work.shortcut"
curl -I "https://raw.githubusercontent.com/YoussefAbdellaoui/Momentum-Bar/main/Shortcuts/MomentumBar-Personal.shortcut"
curl -I "https://raw.githubusercontent.com/YoussefAbdellaoui/Momentum-Bar/main/Shortcuts/MomentumBar-Sleep.shortcut"
curl -I "https://raw.githubusercontent.com/YoussefAbdellaoui/Momentum-Bar/main/Shortcuts/MomentumBar-Focus-Off.shortcut"
```

**Verification Checklist:**
- [ ] All 5 shortcuts created in Shortcuts app
- [ ] All 5 .shortcut files exported to `Shortcuts/` folder
- [ ] All 5 files committed and pushed to GitHub
- [ ] All 5 URLs return 200 OK
- [ ] Test: Click a GitHub raw URL in browser, file should download

**Important Notes:**
- ⚠️ **Exact naming is critical** - App looks for these exact names
- ⚠️ If URLs don't work, check branch name (main vs master)
- ⚠️ GitHub may take 1-2 minutes to make files available after push
- ⚠️ Users won't be able to auto-install until this step is complete

---

## 📋 Phase 1: Critical Requirements (MUST DO NEXT)

### 1. ⚠️ Create App Icons
**Status:** ❌ NOT STARTED
**Priority:** CRITICAL
**Timeline:** 1-2 hours

**Required icon sizes:**
- [ ] 16x16 @1x (16px)
- [ ] 16x16 @2x (32px)
- [ ] 32x32 @1x (32px)
- [ ] 32x32 @2x (64px)
- [ ] 128x128 @1x (128px)
- [ ] 128x128 @2x (256px)
- [ ] 256x256 @1x (256px)
- [ ] 256x256 @2x (512px)
- [ ] 512x512 @1x (512px)
- [ ] 512x512 @2x (1024px)

**Tools:**
- Design tool: Figma, Sketch, or Photoshop
- Generator: https://www.appicon.co/ (easiest)
- Alternative: Hire on Fiverr ($20-50, 24-48 hours)

**Location:** `/MomentumBar/Assets.xcassets/AppIcon.appiconset/`

**Verification:**
```bash
ls -la MomentumBar/Assets.xcassets/AppIcon.appiconset/*.png
# Should show 10 PNG files
```

---

### 2. 💳 Apple Developer Account
**Status:** ❌ NOT STARTED
**Priority:** CRITICAL
**Cost:** $99/year
**Timeline:** 24-48 hours (approval time)

**Steps:**
- [ ] Go to https://developer.apple.com/programs/enroll/
- [ ] Enroll as Individual Developer
- [ ] Pay $99 (credit card)
- [ ] Wait for approval email (usually 24-48 hours)
- [ ] Complete account setup

**Important:** You CANNOT proceed with code signing without this!

**After approval:**
- [ ] Open Xcode > Settings > Accounts
- [ ] Add Apple ID
- [ ] Download certificates
- [ ] Verify Team ID shows: 3CAJN6L683
- [ ] Download "Developer ID Application" certificate

---

## 📋 Phase 2: Backend Infrastructure

### 3. 🚀 Deploy Backend to Railway
**Status:** ❌ NOT STARTED
**Priority:** HIGH
**Timeline:** 2-4 hours

**Prerequisites:**
- [ ] Railway account (sign up at https://railway.app)
- [ ] GitHub repo connected (already done: YoussefAbdellaoui/Momentum-Bar)

**Deployment steps:**
```bash
# Install Railway CLI
brew install railway

# Login
railway login

# Initialize project
cd backend
railway init

# Deploy
railway up

# Your URL will be something like:
# https://momentum-bar-production.up.railway.app
```

**Configure in Railway Dashboard:**
- [ ] Add PostgreSQL database (Railway will auto-provision)
- [ ] Set environment variables (see section below)
- [ ] Initialize database schema
- [ ] Verify health endpoint returns 200

**Initialize Database:**
```bash
railway run npm run db:init
```

**Migrate existing Stripe columns (one-time):**
```bash
railway run npm run db:migrate:dodo
```

**Test deployment:**
```bash
curl https://your-railway-url/health
# Should return: {"status":"ok","timestamp":"..."}
```

**Environment Variables to Set:**

| Variable | Value | Where to get it |
|----------|-------|----------------|
| `DATABASE_URL` | Auto-provided by Railway | N/A |
| `NODE_ENV` | `production` | Manual |
| `PORT` | `3000` | Manual |
| `DODO_PAYMENTS_API_KEY` | `dodo_live_...` | Dodo Payments dashboard |
| `DODO_PAYMENTS_WEBHOOK_KEY` | `whk_...` | Dodo Payments webhook settings |
| `DODO_PAYMENTS_ENVIRONMENT` | `live_mode` | Manual (`test_mode` or `live_mode`) |
| `DODO_PRODUCT_SOLO` | `prod_...` | Dodo Payments product catalog |
| `DODO_PRODUCT_MULTIPLE` | `prod_...` | Dodo Payments product catalog |
| `DODO_PRODUCT_ENTERPRISE` | `prod_...` | Dodo Payments product catalog |
| `RESEND_API_KEY` | `re_...` | resend.com/api-keys |
| `EMAIL_FROM` | `MomentumBar <noreply@yourdomain.com>` | Your verified domain |
| `ADMIN_API_KEY` | Generate random string | Use: `openssl rand -hex 32` |
| `ALLOWED_ORIGINS` | `https://momentumbar.app,https://www.momentumbar.app` | Your website URLs |

**Update app if Railway URL is different:**
- [ ] If URL ≠ `https://momentum-bar-production.up.railway.app`
- [ ] Update `MomentumBar/Services/LicenseAPIClient.swift` line 20
- [ ] Change `baseURL` to your actual Railway URL

---

### 4. 💰 Configure Dodo Payments
**Status:** ❌ NOT STARTED
**Priority:** HIGH
**Timeline:** 1-2 hours

**Steps:**

**A. Create Dodo Payments Account**
- [ ] Sign up in the Dodo Payments dashboard
- [ ] Complete business verification
- [ ] Switch to Live mode (important!)

**B. Create Products**
- [ ] Create 3 products in Dodo Payments:
- [ ] Create 3 products:

**Solo Tier:**
- Name: "MomentumBar Solo"
- Price: $14.99 USD
- Type: One-time payment
- Copy `prod_...` ID → Add to Railway env as `DODO_PRODUCT_SOLO`

**Multiple Tier:**
- Name: "MomentumBar Multiple"
- Price: $24.99 USD
- Type: One-time payment
- Copy `prod_...` ID → Add to Railway env as `DODO_PRODUCT_MULTIPLE`

**Enterprise Tier:**
- Name: "MomentumBar Enterprise"
- Price: $64.99 USD
- Type: One-time payment
- Copy `prod_...` ID → Add to Railway env as `DODO_PRODUCT_ENTERPRISE`

**C. Configure Webhook**
- [ ] Add a webhook endpoint in Dodo Payments
- [ ] URL: `https://your-railway-url/webhooks/dodo`
- [ ] Events to listen: `payment.succeeded` (and `payment.failed` if desired)
- [ ] Copy webhook key → Add to Railway as `DODO_PAYMENTS_WEBHOOK_KEY`

**D. Get API Keys**
- [ ] Copy "API key"
- [ ] Add to Railway env as `DODO_PAYMENTS_API_KEY`
- [ ] Set `DODO_PAYMENTS_ENVIRONMENT` to `test_mode` while testing, then `live_mode`

**E. Test Payment (Use Dodo Payments Test Mode First!)**
- [ ] Open your Dodo checkout link for the Solo product
- [ ] Complete a test purchase with Dodo’s test card details (from their docs)
- [ ] Confirm the backend received `payment.succeeded` and generated a license

---

### 5. 📧 Configure Resend Email
**Status:** ❌ NOT STARTED
**Priority:** HIGH
**Timeline:** 1-2 hours

**Steps:**

**A. Create Resend Account**
- [ ] Sign up at https://resend.com
- [ ] Verify your email

**B. Add Domain**
- [ ] Go to Domains → Add Domain
- [ ] Enter your domain (e.g., `momentumbar.app`)
- [ ] Add DNS records to your domain registrar:
  - SPF record
  - DKIM record
  - Return-Path record
- [ ] Wait for verification (can take up to 48 hours)

**Alternative: Use Resend's Shared Domain**
- If you don't have a domain yet, use `resend.dev` (free tier)
- Email will be from: `onboarding@resend.dev`
- Less professional but works for testing

**C. Get API Key**
- [ ] Go to https://resend.com/api-keys
- [ ] Create new API key
- [ ] Name it: "MomentumBar Production"
- [ ] Copy key (starts with `re_...`)
- [ ] Add to Railway env as `RESEND_API_KEY`

**D. Configure Email Template**
- [ ] Verify email templates exist in `backend/email-templates/`
- [ ] Test sending email:

```bash
# SSH into Railway container
railway shell

# Send test email
node -e "
const { Resend } = require('resend');
const resend = new Resend(process.env.RESEND_API_KEY);
resend.emails.send({
  from: 'MomentumBar <noreply@yourdomain.com>',
  to: 'your-email@example.com',
  subject: 'Test Email',
  html: '<p>Testing Resend integration</p>'
});
"
```

**E. Update Environment**
- [ ] Set `EMAIL_FROM` in Railway env
- [ ] Format: `MomentumBar <noreply@yourdomain.com>`

---

### 6. 🧪 Test Backend API
**Status:** ❌ NOT STARTED
**Priority:** HIGH
**Timeline:** 1 hour

**Test all endpoints:**

**Health Check:**
```bash
curl https://your-railway-url/health
# Expected: {"status":"ok","timestamp":"2026-01-20T..."}
```

**License Activation (should fail - no license yet):**
```bash
curl -X POST https://your-railway-url/api/v1/license/activate \
  -H "Content-Type: application/json" \
  -d '{
    "licenseKey": "SOLO-TEST-12345-67890",
    "hardwareId": "test-hardware-id-12345",
    "machineName": "Test Mac",
    "appVersion": "1.0"
  }'
# Expected: 404 or 400 (license not found - this is correct!)
```

**License Validation:**
```bash
curl -X POST https://your-railway-url/api/v1/license/validate \
  -H "Content-Type: application/json" \
  -d '{
    "licenseKey": "SOLO-TEST-12345-67890",
    "hardwareId": "test-hardware-id-12345"
  }'
# Expected: {"valid":false,"message":"License not found"}
```

**Dodo Payments webhook (manual test via dashboard):**
- [ ] Go to Dodo Payments dashboard → Webhooks
- [ ] Click your webhook endpoint
- [ ] Click "Send test webhook"
- [ ] Select `payment.succeeded`
- [ ] Verify backend receives and processes it

**Database Connection:**
```bash
railway run psql $DATABASE_URL -c "SELECT COUNT(*) FROM licenses;"
# Should return a count (even if 0)
```

---

## 📋 Phase 3: Build & Code Signing

### 7. 🔨 Build Release App
**Status:** ❌ NOT STARTED
**Priority:** HIGH
**Timeline:** 30 minutes
**Requires:** Apple Developer account approved + certificate downloaded

**Pre-build verification:**
```bash
# Check deployment target
grep "MACOSX_DEPLOYMENT_TARGET" MomentumBar.xcodeproj/project.pbxproj
# Should show: 14.0 (NOT 26.2)

# Check version
grep "MARKETING_VERSION" MomentumBar.xcodeproj/project.pbxproj
# Should show: 1.0

# Check app icons exist
ls -la MomentumBar/Assets.xcassets/AppIcon.appiconset/*.png | wc -l
# Should show: 10
```

**Build via Xcode (Recommended):**
- [ ] Open `MomentumBar.xcodeproj` in Xcode
- [ ] Select target: "Any Mac (Apple Silicon, Intel)"
- [ ] Product → Scheme → Edit Scheme
- [ ] Set Build Configuration: Release
- [ ] Product → Archive
- [ ] Wait for archive to complete (2-5 minutes)
- [ ] Window → Organizer will open automatically

**Build via Command Line (Alternative):**
```bash
xcodebuild -scheme MomentumBar \
  -configuration Release \
  -archivePath "$PWD/build/MomentumBar.xcarchive" \
  archive

# Verify archive created
ls -lh build/MomentumBar.xcarchive
```

---

### 8. 🔐 Code Sign & Notarize
**Status:** ❌ NOT STARTED
**Priority:** CRITICAL
**Timeline:** 30-45 minutes (includes Apple notarization time)
**Requires:** Apple Developer ID Application certificate

**In Xcode Organizer:**

**A. Export for Distribution**
- [ ] Select your archive
- [ ] Click "Distribute App"
- [ ] Select: **"Developer ID"** (NOT "App Store Connect")
- [ ] Select: **"Upload"** (for automatic notarization)
- [ ] Distribution options:
  - App Thinning: None
  - Rebuild from Bitcode: No
  - Strip Swift symbols: Yes (optional)
  - Include manifest: No
- [ ] Select signing certificate: "Developer ID Application: Your Name (3CAJN6L683)"
- [ ] Click "Upload"
- [ ] Wait for upload to complete

**B. Wait for Notarization**
- [ ] Apple will email you when notarization completes (15-30 minutes)
- [ ] Or check status: Window → Organizer → Archives → Your archive

**Check notarization status:**
```bash
xcrun notarytool history \
  --apple-id your@email.com \
  --team-id 3CAJN6L683 \
  --password "app-specific-password"

# Create app-specific password at:
# https://appleid.apple.com/account/manage → Sign-In and Security → App-Specific Passwords
```

**C. Export Notarized App**
- [ ] Once notarization succeeds, click "Export"
- [ ] Choose export location: `build/export/`
- [ ] Xcode will export `MomentumBar.app` with notarization ticket stapled

**Verify notarization:**
```bash
spctl -a -vv build/export/MomentumBar.app
# Should show: "source=Notarized Developer ID"

xcrun stapler validate build/export/MomentumBar.app
# Should show: "The validate action worked!"
```

---

### 9. 📦 Create DMG Installer
**Status:** ❌ NOT STARTED
**Priority:** HIGH
**Timeline:** 15-30 minutes

**Option A: Using create-dmg (Recommended)**

**Install create-dmg:**
```bash
brew install create-dmg
```

**Create DMG:**
```bash
# Create DMG with nice layout
create-dmg \
  --volname "MomentumBar" \
  --volicon "MomentumBar/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "MomentumBar.app" 200 190 \
  --hide-extension "MomentumBar.app" \
  --app-drop-link 600 185 \
  --background "path/to/background.png" \
  "build/MomentumBar-1.0.dmg" \
  "build/export/"

# If you don't have a background image, omit --background flag
```

**Option B: Manual DMG Creation**

```bash
# Create temporary folder
mkdir -p build/dmg-temp
cp -R build/export/MomentumBar.app build/dmg-temp/

# Create Applications symlink
ln -s /Applications build/dmg-temp/Applications

# Create DMG
hdiutil create \
  -volname "MomentumBar" \
  -srcfolder build/dmg-temp \
  -ov \
  -format UDZO \
  build/MomentumBar-1.0.dmg

# Cleanup
rm -rf build/dmg-temp
```

**Sign the DMG:**
```bash
codesign \
  --sign "Developer ID Application: Your Name (3CAJN6L683)" \
  build/MomentumBar-1.0.dmg

# Verify signature
codesign -vv build/MomentumBar-1.0.dmg
```

**Notarize the DMG:**
```bash
# Submit for notarization
xcrun notarytool submit build/MomentumBar-1.0.dmg \
  --apple-id your@email.com \
  --team-id 3CAJN6L683 \
  --password "app-specific-password" \
  --wait

# Once approved, staple the ticket
xcrun stapler staple build/MomentumBar-1.0.dmg

# Verify
xcrun stapler validate build/MomentumBar-1.0.dmg
spctl -a -t open --context context:primary-signature -v build/MomentumBar-1.0.dmg
```

**Final verification:**
```bash
# Check file size (should be reasonable, e.g., < 50MB)
ls -lh build/MomentumBar-1.0.dmg

# Test mounting
hdiutil attach build/MomentumBar-1.0.dmg
# Should mount without errors

# Unmount
hdiutil detach /Volumes/MomentumBar
```

---

## 📋 Phase 4: Distribution

### 10. 📤 Upload to GitHub Releases
**Status:** ❌ NOT STARTED
**Priority:** HIGH
**Timeline:** 15 minutes

**Create Git Tag:**
```bash
# Tag the release
git tag -a v1.0.0 -m "MomentumBar v1.0.0 - Initial Release"
git push origin v1.0.0
```

**Create GitHub Release:**
- [ ] Go to https://github.com/YoussefAbdellaoui/Momentum-Bar/releases
- [ ] Click "Draft a new release"
- [ ] Choose tag: v1.0.0
- [ ] Release title: "MomentumBar v1.0.0"
- [ ] Description:

```markdown
# MomentumBar v1.0.0 - Initial Release

The first stable release of MomentumBar - your multi-timezone menu bar companion for macOS.

## 🎉 Features

- Multi-timezone display in menu bar
- Calendar integration with upcoming meetings
- Day/night awareness with sunrise/sunset calculations
- Pomodoro timer with desktop widget
- Focus Mode integration
- Global keyboard shortcuts
- Meeting analytics and conflict detection
- Team coworker timezone visibility
- 3-day free trial included

## 📥 Installation

1. Download `MomentumBar-1.0.dmg`
2. Open the DMG file
3. Drag **MomentumBar** to **Applications** folder
4. **Right-click** MomentumBar → **Open** (first time only)
5. Start your free 3-day trial!

## 💳 Purchase License

Visit [momentumbar.app](https://momentumbar.app) to purchase a license after your trial.

**Pricing:**
- Solo: $14.99 (1 Mac)
- Multiple: $24.99 (3 Macs)
- Enterprise: $64.99+ (Team seats)

## ⚙️ System Requirements

- macOS 14.0 (Sonoma) or later
- Calendar access for event integration
- Internet connection for license activation

## 🐛 Known Issues

None

## 📝 Changelog

- Initial release
```

- [ ] Upload file: Drag `build/MomentumBar-1.0.dmg` to release assets
- [ ] Check "Set as the latest release"
- [ ] Click "Publish release"

**Your download URL will be:**
```
https://github.com/YoussefAbdellaoui/Momentum-Bar/releases/download/v1.0.0/MomentumBar-1.0.dmg
```

**Test download link:**
```bash
curl -L -I https://github.com/YoussefAbdellaoui/Momentum-Bar/releases/download/v1.0.0/MomentumBar-1.0.dmg
# Should return: HTTP/2 200
```

---

### 11. 🌐 Update Website
**Status:** ❌ NOT STARTED
**Priority:** HIGH
**Timeline:** 2-4 hours

**A. Add Download Page**

Create or update your landing page with download section:

```tsx
// Example: app/page.tsx or components/Hero.tsx

export default function HomePage() {
  const downloadUrl = "https://github.com/YoussefAbdellaoui/Momentum-Bar/releases/download/v1.0.0/MomentumBar-1.0.dmg";

  return (
    <div>
      {/* Hero Section */}
      <section className="hero">
        <h1>MomentumBar</h1>
        <p>Multi-timezone management for remote teams</p>

        <a
          href={downloadUrl}
          className="download-button"
          download
        >
          Download for macOS
          <span className="version">Free 3-day trial • macOS 14.0+</span>
        </a>
      </section>

      {/* Installation Instructions */}
      <section className="installation">
        <h2>How to Install</h2>
        <ol>
          <li>Download MomentumBar-1.0.dmg</li>
          <li>Open the DMG file</li>
          <li>Drag MomentumBar to Applications folder</li>
          <li><strong>Right-click → Open</strong> (first time only)</li>
        </ol>

        <div className="security-notice">
          <h3>⚠️ macOS Security Notice</h3>
          <p>
            When opening MomentumBar for the first time, macOS may show a security warning.
            This is normal for apps downloaded outside the App Store.
          </p>
          <p>
            <strong>Right-click</strong> the app and choose <strong>Open</strong> to bypass this.
            The app is signed and notarized by Apple.
          </p>
        </div>
      </section>

      {/* System Requirements */}
      <section className="requirements">
        <h3>System Requirements</h3>
        <ul>
          <li>macOS 14.0 (Sonoma) or later</li>
          <li>Calendar access for event integration</li>
          <li>Internet connection for license activation</li>
        </ul>
      </section>
    </div>
  );
}
```

**B. Add Pricing/Purchase Page**

Create Dodo Payments checkout integration:

```tsx
// app/pricing/page.tsx
'use client';

const checkoutBaseUrl =
  process.env.NEXT_PUBLIC_DODO_CHECKOUT_BASE_URL ||
  'https://checkout.dodopayments.com/buy';
const redirectUrl = process.env.NEXT_PUBLIC_DODO_CHECKOUT_REDIRECT_URL;

const buildCheckoutUrl = (productId: string) => {
  const base = `${checkoutBaseUrl}/${productId}`;
  if (!redirectUrl) return base;
  return `${base}?redirect_url=${encodeURIComponent(redirectUrl)}`;
};

export default function PricingPage() {
  const handlePurchase = (productId: string) => {
    window.location.href = buildCheckoutUrl(productId);
  };

  return (
    <div className="pricing">
      <h1>Pricing</h1>

      <div className="tiers">
        {/* Solo Tier */}
        <div className="tier">
          <h3>Solo</h3>
          <p className="price">$14.99</p>
          <ul>
            <li>1 Mac</li>
            <li>All features</li>
            <li>Free updates</li>
            <li>Email support</li>
          </ul>
          <button onClick={() => handlePurchase(process.env.NEXT_PUBLIC_DODO_PRODUCT_SOLO!)}>
            Purchase Solo
          </button>
        </div>

        {/* Multiple Tier */}
        <div className="tier featured">
          <h3>Multiple</h3>
          <p className="price">$24.99</p>
          <ul>
            <li>3 Macs</li>
            <li>All features</li>
            <li>Free updates</li>
            <li>Priority support</li>
          </ul>
          <button onClick={() => handlePurchase(process.env.NEXT_PUBLIC_DODO_PRODUCT_MULTIPLE!)}>
            Purchase Multiple
          </button>
        </div>

        {/* Enterprise Tier */}
        <div className="tier">
          <h3>Enterprise</h3>
          <p className="price">$64.99+</p>
          <ul>
            <li>Team seats</li>
            <li>All features</li>
            <li>Free updates</li>
            <li>Priority support</li>
          </ul>
          <button onClick={() => handlePurchase(process.env.NEXT_PUBLIC_DODO_PRODUCT_ENTERPRISE!)}>
            Purchase Enterprise
          </button>
        </div>
      </div>
    </div>
  );
}
```

**C. Environment Variables for Website**

Create `.env.production`:
```bash
NEXT_PUBLIC_DODO_CHECKOUT_BASE_URL=https://checkout.dodopayments.com/buy
NEXT_PUBLIC_DODO_CHECKOUT_REDIRECT_URL=https://momentumbar.app/success
NEXT_PUBLIC_DODO_PRODUCT_SOLO=prod_...
NEXT_PUBLIC_DODO_PRODUCT_MULTIPLE=prod_...
NEXT_PUBLIC_DODO_PRODUCT_ENTERPRISE=prod_...
NEXT_PUBLIC_API_URL=https://momentum-bar-production.up.railway.app
NEXT_PUBLIC_DMG_URL=https://github.com/YoussefAbdellaoui/Momentum-Bar/releases/download/v1.0.0/MomentumBar-1.0.dmg
```

**D. Deploy Website**

```bash
cd website

# Install dependencies
npm install

# Build
npm run build

# Deploy to Vercel (recommended)
npx vercel --prod

# Or deploy to Netlify
npx netlify deploy --prod
```

**E. Add Required Pages**

- [ ] Privacy Policy (required for Calendar access)
- [ ] Terms of Service
- [ ] Support/Contact page
- [ ] FAQ page

---

## 📋 Phase 5: Final Testing

### 12. 🧪 End-to-End Testing
**Status:** ❌ NOT STARTED
**Priority:** CRITICAL
**Timeline:** 4-8 hours

**A. Fresh Mac Install Test**

Ideally test on a clean Mac or create a new macOS user:

```bash
# Create test user
sudo dscl . -create /Users/testuser
sudo dscl . -create /Users/testuser UserShell /bin/bash
sudo dscl . -create /Users/testuser RealName "Test User"
sudo dscl . -create /Users/testuser UniqueID 1001
sudo dscl . -create /Users/testuser PrimaryGroupID 20
sudo dscl . -create /Users/testuser NFSHomeDirectory /Users/testuser
sudo dscl . -passwd /Users/testuser password
```

**Test Checklist:**

**Installation Flow:**
- [ ] Download DMG from website
- [ ] Open DMG file
- [ ] Drag to Applications
- [ ] First launch: Right-click → Open works without errors
- [ ] App appears in menu bar (no dock icon by default ✓)
- [ ] Grant Calendar permission when prompted
- [ ] Onboarding flow appears for first-time user

**Trial Flow:**
- [ ] Trial starts automatically (3 days)
- [ ] Trial status shows in Settings
- [ ] Trial countdown is accurate
- [ ] App fully functional during trial

**Purchase & Activation Flow:**
- [ ] Go to website pricing page
- [ ] Click "Purchase Solo"
- [ ] Dodo checkout loads
- [ ] Complete payment in test mode
- [ ] Receive license key email
- [ ] Copy license key
- [ ] Open app → Settings → License
- [ ] Paste and activate key
- [ ] Activation succeeds
- [ ] License status shows "Licensed"
- [ ] Trial info disappears

**Multi-Machine Testing:**
- [ ] Activate Solo license on second Mac → Should fail (limit reached)
- [ ] Deactivate from first Mac
- [ ] Activate on second Mac → Should succeed
- [ ] Purchase Multiple license
- [ ] Activate on 3 different Macs → All should succeed
- [ ] Try 4th Mac → Should fail

**Offline Mode:**
- [ ] Activate license while online
- [ ] Disconnect from internet
- [ ] Quit and restart app
- [ ] App should work normally (30-day cache)
- [ ] Reconnect internet
- [ ] App should phone home in background

**Core Functionality:**
- [ ] Add timezone → Works
- [ ] Delete timezone → Works
- [ ] Reorder timezones → Works
- [ ] Pin timezone to menu bar → Works (max 5)
- [ ] Calendar events appear → Works
- [ ] Meeting reminders work → Works
- [ ] Day/night indicator accurate → Works
- [ ] Sunrise/sunset times correct → Works
- [ ] Pomodoro timer works → Works
- [ ] Focus Mode integration → Works
- [ ] Global hotkeys work → Works
- [ ] Settings persist → Works
- [ ] Widget sync works → Works

**Performance:**
- [ ] Add 10+ timezones → No lag
- [ ] Add 20+ calendar events → No lag
- [ ] Monitor CPU usage (should be < 1% idle)
- [ ] Monitor memory usage (should be < 100MB)
- [ ] Menu bar responds instantly

**Edge Cases:**
- [ ] Deny Calendar permission → App shows helpful error
- [ ] Invalid license key → Shows clear error message
- [ ] Network error during activation → Shows retry option
- [ ] Trial expires → Shows modal to purchase
- [ ] License revoked (test via admin API) → App blocks access

---

## 📋 Phase 6: Launch Preparation

### 13. 📱 Marketing & Support Setup
**Status:** ❌ NOT STARTED
**Priority:** MEDIUM
**Timeline:** Ongoing

**Pre-Launch:**
- [ ] Set up support email (e.g., support@momentumbar.app)
- [ ] Create social media accounts (Twitter, Reddit)
- [ ] Prepare launch announcement
- [ ] Create demo video/GIF
- [ ] Prepare screenshots for website
- [ ] Write blog post/launch story

**Launch Channels:**
- [ ] Product Hunt (schedule launch day)
- [ ] Hacker News "Show HN"
- [ ] Reddit: r/macapps, r/productivity
- [ ] Twitter/X announcement
- [ ] IndieHackers
- [ ] MacRumors forums

**Monitoring Setup:**
- [ ] Set up error tracking (Sentry, Bugsnag)
- [ ] Set up analytics (Plausible, Fathom)
- [ ] Monitor Railway logs
- [ ] Monitor Dodo Payments dashboard
- [ ] Set up uptime monitoring (UptimeRobot)

---

## 📋 Phase 7: Go Live!

### 14. 🚀 Launch Day Checklist
**Status:** ❌ NOT STARTED
**Priority:** CRITICAL
**Timeline:** Launch day

**Morning Before Launch:**

**Backend Health Check:**
- [ ] Railway server running: `curl https://your-railway-url/health`
- [ ] Database connected: `railway run psql $DATABASE_URL -c "SELECT 1;"`
- [ ] Dodo Payments live mode enabled
- [ ] Resend emails working

**Website Check:**
- [ ] Download link works
- [ ] Dodo checkout works
- [ ] All pages load correctly
- [ ] Mobile responsive
- [ ] SSL certificate valid

**App Check:**
- [ ] DMG downloads successfully
- [ ] App launches without errors
- [ ] License activation works
- [ ] All features functional

**Switch to Production:**
- [ ] Dodo Payments: Switch from Test mode to Live mode
- [ ] Update all Dodo Payments environment variables in Railway
- [ ] Test one real purchase (then refund if needed)
- [ ] Verify license email arrives

**Launch Sequence:**
- [ ] 9:00 AM: Final system check
- [ ] 10:00 AM: Post to Product Hunt
- [ ] 10:30 AM: Post to Hacker News
- [ ] 11:00 AM: Post to Reddit
- [ ] 11:30 AM: Tweet announcement
- [ ] 12:00 PM: Email newsletter (if you have one)

**Throughout Launch Day:**
- [ ] Monitor error logs every hour
- [ ] Respond to comments/questions
- [ ] Track downloads and purchases
- [ ] Fix critical bugs immediately
- [ ] Collect user feedback

---

## 📊 Success Metrics

**Track these KPIs:**

| Metric | Target | How to Measure |
|--------|--------|----------------|
| Downloads | 100+ day 1 | GitHub release stats |
| Trial activations | 50+ day 1 | Railway logs |
| Purchases | 5+ day 1 | Dodo Payments dashboard |
| Conversion rate | 5%+ | Purchases / Trials |
| Support tickets | < 10 day 1 | Support email |
| Crashes | 0 | Error tracking |
| Uptime | 99.9%+ | UptimeRobot |

---

## 🐛 Common Issues & Solutions

### Issue: "App is damaged and can't be opened"
**Solution:** App wasn't properly signed/notarized. Re-sign and notarize.

### Issue: Gatekeeper warning on first launch
**Solution:** Normal! Tell users to right-click → Open.

### Issue: Calendar permission denied
**Solution:** System Preferences → Security & Privacy → Calendar → Grant access.

### Issue: License activation fails
**Solution:** Check backend logs, verify network connectivity, check Dodo Payments webhook.

### Issue: App doesn't appear in menu bar
**Solution:** Check display settings, verify menu bar isn't full, restart app.

### Issue: Trial doesn't start
**Solution:** Check keychain access, verify first launch detection.

---

## ✅ Final Pre-Launch Checklist

**Before you click "Launch":**

- [ ] ✅ App icons created (10 PNG files)
- [ ] ✅ Apple Developer account approved
- [ ] ✅ Developer ID certificate obtained
- [ ] ✅ Backend deployed to Railway
- [ ] ✅ PostgreSQL database initialized
- [ ] ✅ Dodo Payments configured (products, webhook, live mode)
- [ ] ✅ Resend configured (domain verified, API key)
- [ ] ✅ App built and signed
- [ ] ✅ App notarized by Apple
- [ ] ✅ DMG created and notarized
- [ ] ✅ DMG uploaded to GitHub Releases
- [ ] ✅ Website updated with download link
- [ ] ✅ Pricing page with Dodo Payments integration
- [ ] ✅ Privacy policy published
- [ ] ✅ Terms of service published
- [ ] ✅ Support email configured
- [ ] ✅ End-to-end testing completed
- [ ] ✅ Test purchase successful
- [ ] ✅ Test license activation successful
- [ ] ✅ Error tracking configured
- [ ] ✅ Launch announcement prepared

**When all boxes are checked:** 🚀 **YOU'RE READY TO LAUNCH!**

---

## 📞 Support Contacts

**Apple Developer:**
- Support: https://developer.apple.com/support/
- Phone: 1-800-633-2152

**Railway:**
- Support: https://railway.app/help
- Discord: https://discord.gg/railway

**Dodo Payments:**
- Support: See Dodo Payments dashboard support links
- Dashboard: https://app.dodopayments.com

**Resend:**
- Support: support@resend.com
- Docs: https://resend.com/docs

---

## 📝 Post-Launch Tasks

**Week 1:**
- [ ] Monitor crash reports daily
- [ ] Respond to all user emails within 24h
- [ ] Fix critical bugs (release v1.0.1 if needed)
- [ ] Collect user feedback
- [ ] Thank early adopters

**Month 1:**
- [ ] Analyze conversion funnel
- [ ] Optimize pricing if needed
- [ ] Plan v1.1 features based on feedback
- [ ] Set up automated backups for database
- [ ] Document common support issues

**Ongoing:**
- [ ] Monthly release cycle
- [ ] Regular backend dependency updates
- [ ] Monitor macOS updates for compatibility
- [ ] Build community
- [ ] Consider App Store submission (optional)

---

**Good luck with your launch! 🎉**

Last updated: 2026-01-20
Version: 1.0.0
Deployment target: macOS 14.0+
