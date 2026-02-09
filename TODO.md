# MomentumBar TODO

## High priority (stability & release quality)
- [x] Create `scripts/release.sh` to build, re-sign Sparkle, notarize DMG + ZIP, update appcast, and verify.
- [x] Add automated release verification step (spctl + stapler + mount checks).
- [x] Add runtime entitlement checks with clear UI fallback for calendar/keychain.

## Product polish (user experience)
- [x] Announcement badge: show unread count in menu bar and allow “mark all read.”
- [x] Calendar UX: show last sync time, manual refresh, and error states.
- [x] Onboarding: delay announcements until onboarding completes.
- [x] Updates screen: show current version, last check, “check now.”

## Widget & settings
- [x] Widget sync status indicator when App Group unavailable.
- [x] Settings: group “About / License / Update” section.
- [x] Add “Reset app data” confirmation flow.

## Performance & reliability
- [x] Add lightweight crash/metrics logging (local only), opt-in toggle.
- [x] Reduce UI redraw frequency when idle.

## Backend & web
- [x] Admin announcements: bulk schedule + “expire now” button.
- [x] License email pipeline: retry queue + dead-letter logging.
- [x] Website: add “Release notes” section with link to appcast notes.
