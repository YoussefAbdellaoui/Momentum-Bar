# Sparkle Release Setup

This app uses Sparkle for auto-updates. The app reads the appcast from:

- `https://momentumbar.app/appcast.xml`

## 1) Generate keys

Sparkle requires an EdDSA key pair. Generate and keep the private key secure.

```
/path/to/Sparkle/bin/generate_keys
```

- Copy the **public key** into Xcode build settings (`SUPublicEDKey`).
- Store the **private key** securely for signing releases.

## 2) Build and sign a release

Create a zipped update from your signed `.app` bundle, then sign it:

```
/path/to/Sparkle/bin/sign_update /path/to/MomentumBar.zip
```

This outputs the `sparkle:edSignature` value for the appcast.

## 3) Update the appcast

Edit `website/public/appcast.xml` and update:

- `sparkle:shortVersionString`
- `sparkle:version` (build number)
- `url` (download URL)
- `length` (file size)
- `sparkle:edSignature` (from `sign_update`)
- `pubDate`

You can generate an `<item>` snippet using:

```
SPARKLE_BIN=/path/to/Sparkle/bin ./sparkle/generate-appcast-entry.sh /path/to/MomentumBar.zip 1.2.3 123 https://momentumbar.app/downloads/MomentumBar-1.2.3.zip
```

Deploy the website so the appcast is publicly available.

## 4) Validate

Sparkle includes a validator to verify the appcast is correct.

```
/path/to/Sparkle/bin/validate_appcast --appcast /path/to/appcast.xml
```
