# Release Process (Pre-Download Checklist)

Use this checklist before publishing a new DMG/ZIP. It documents the exact steps used for MomentumBar releases.

## 1) Bump Version & Build
- Update marketing version (e.g., `1.0.2`) and build number (e.g., `4`) in:
  - `MomentumBar.xcodeproj/project.pbxproj`

## 2) Build Release
```
xcodebuild -scheme MomentumBar -configuration Release -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

## 3) Code Sign the App
```
codesign --force --deep --options runtime --sign "Developer ID Application: Youssef Abdellaoui (3CAJN6L683)" "<DerivedData>/Build/Products/Release/MomentumBar.app"
```

## 4) Sparkle ZIP (Updates)
- Create a ZIP without resource forks:
```
ditto -c -k --keepParent --norsrc --noextattr "<DerivedData>/Build/Products/Release/MomentumBar.app" dist/MomentumBar-<version>.zip
```
- Notarize + staple the app:
```
xcrun notarytool submit dist/MomentumBar-<version>.zip --apple-id "<apple id>" --team-id "3CAJN6L683" --password "<app-specific-password>" --wait
xcrun stapler staple "<DerivedData>/Build/Products/Release/MomentumBar.app"
```
- Update appcast:
```
SPARKLE_BIN="/tmp/sparkle/bin" SPARKLE_PRIVATE_KEY="<base64 ed25519>" \
  ./sparkle/update-appcast.sh dist/MomentumBar-<version>.zip <version> <build> \
  https://momentumbar.app/downloads/MomentumBar-<version>.zip website/public/appcast.xml
```

## 5) DMG (New Downloads)
- Build a Finder DMG (simple Apple style):
  - App + Applications shortcut
  - Background instructions (generated PNG)
  - Then convert, sign, notarize, staple.
```
hdiutil create -volname MomentumBar -srcfolder /tmp/MomentumBarDmgRoot -ov -format UDRW /tmp/MomentumBar-rw.dmg
... set Finder layout/background ...
hdiutil convert /tmp/MomentumBar-rw.dmg -format UDZO -o dist/MomentumBar-<version>.dmg
codesign --force --sign "Developer ID Application: Youssef Abdellaoui (3CAJN6L683)" --timestamp dist/MomentumBar-<version>.dmg
xcrun notarytool submit dist/MomentumBar-<version>.dmg --apple-id "<apple id>" --team-id "3CAJN6L683" --password "<app-specific-password>" --wait
xcrun stapler staple dist/MomentumBar-<version>.dmg
```

## 6) Publish Website Artifacts
- Copy artifacts:
```
cp dist/MomentumBar-<version>.zip website/public/downloads/
cp dist/MomentumBar-<version>.dmg website/public/downloads/
```
- Update the download button:
  - `website/src/components/Download.tsx`
- Deploy the website.

## 7) Quick Verification (post-deploy)
```
xcrun stapler validate ~/Downloads/MomentumBar-<version>.dmg
hdiutil attach ~/Downloads/MomentumBar-<version>.dmg -nobrowse
spctl -a -vv /Volumes/MomentumBar/MomentumBar.app
```

Notes:
- Sparkle uses the ZIP; the DMG is for first-time downloads.
- If Gatekeeper blocks the DMG, it usually means a cached or unsigned DMG was served.
