# DMG Build, Sign, Notarize, Verify Guide

This guide is the canonical checklist for producing a **clean, notarized DMG** that installs smoothly and updates via Sparkle.

## 0) Prereqs
- Build config: Release
- App already code-signed **with entitlements**
- Sparkle appcast updated **after** final ZIP is notarized
- Apple credentials available:
  - `SIGN_IDENTITY` (Developer ID Application)
  - `APPLE_ID`, `TEAM_ID`, `APP_PASSWORD`

## 1) Build the app
```
xcodebuild -scheme MomentumBar -configuration Release -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

## 2) Re-sign the app (keep entitlements)
```
APP_PATH="/Users/$USER/Library/Developer/Xcode/DerivedData/MomentumBar-*/Build/Products/Release/MomentumBar.app"
codesign --force --options runtime \
  --entitlements MomentumBar/MomentumBar.entitlements \
  --sign "Developer ID Application: Youssef Abdellaoui (3CAJN6L683)" \
  "$APP_PATH"
```

Verify entitlements:
```
codesign -d --entitlements :- --xml "$APP_PATH" | head -n 20
```

## 3) Build, sign, notarize the DMG
```
SIGN_IDENTITY="Developer ID Application: Youssef Abdellaoui (3CAJN6L683)" \
APPLE_ID="kenicastrocantabria@gmail.com" \
TEAM_ID="3CAJN6L683" \
APP_PASSWORD="kime-cvlj-ypjq-wsmu" \
scripts/build-dmg.sh 1.0.3 "$APP_PATH"
```

Output DMG:
```
/private/tmp/MomentumBar-1.0.3.dmg
```

## 4) Verify the DMG and app inside it
```
spctl -a -vv /private/tmp/MomentumBar-1.0.3.dmg
xcrun stapler validate /private/tmp/MomentumBar-1.0.3.dmg

hdiutil attach /private/tmp/MomentumBar-1.0.3.dmg -nobrowse
spctl -a -vv "/Volumes/MomentumBar Installer 1.0.3/MomentumBar.app"
xcrun stapler validate "/Volumes/MomentumBar Installer 1.0.3/MomentumBar.app"
hdiutil detach "/Volumes/MomentumBar Installer 1.0.3"
```

Notes:
- `spctl` on the **DMG** often says “valid but not an app.” That’s fine.  
  The **app inside** must say “accepted” and “Notarized Developer ID.”

## 5) Publish
```
mv /private/tmp/MomentumBar-1.0.3.dmg website/public/downloads/
```

## 6) Sparkle update ZIP (if releasing update)
Use the ZIP workflow **after** signing the app with entitlements:
```
ditto -c -k --keepParent --norsrc --noextattr "$APP_PATH" dist/MomentumBar-1.0.3.zip
xcrun notarytool submit dist/MomentumBar-1.0.3.zip --apple-id "$APPLE_ID" --team-id "$TEAM_ID" --password "$APP_PASSWORD" --wait
```
Then update appcast:
```
SPARKLE_BIN="/tmp/sparkle/bin" \
SPARKLE_PRIVATE_KEY="<private-key>" \
./sparkle/update-appcast.sh dist/MomentumBar-1.0.3.zip 1.0.3 5 \
  https://momentumbar.app/downloads/MomentumBar-1.0.3.zip \
  website/public/appcast.xml
```

## Troubleshooting
- **“Device not configured”** from `hdiutil`:
  - Ensure nothing is mounted at `/Volumes/MomentumBar*`
  - Detach: `hdiutil detach /Volumes/MomentumBar\ Installer\ <version>`
- **DMG looks like zlib**:
  - You copied the wrong file. Use `/private/tmp/MomentumBar-<version>.dmg`
- **Calendar permission issue after Sparkle update**:
  - App must be re-signed with entitlements before packaging.
