# Build and verification handoff

Final packaging checked: 18 October 2026, 19:54 Asia/Dhaka.

## Results

- Flutter static analysis: no issues found.
- Flutter tests: 10 passed, including API retry-key reuse, rejection of foreign token-bearing URLs, Dhaka time conversion, exact BDT input conversion, phone/tablet/desktop layout, every admin destination, staff navigation restrictions, unavailable room selection, validation and larger accessibility text.
- Android debug APK compiled successfully. The project disables Kotlin incremental caches to avoid the Windows cross-drive Pub-cache issue encountered during the build.
- Web release review build compiled successfully, with local renderer assets and both bundled font licenses.
- Laravel suite: 49 tests / 238 assertions passed after the Flutter CORS configuration was added. Allowed and untrusted origins were checked.
- Real Flutter browser checks used only the disposable backend testing database: login, secure session restoration, dashboard, bookings, confirmed details, approved edit from revision 2 to 3, server quote, creation of a draft, and authenticated PDF preparation.
- Phone layout was visually checked at 375px; automated layout tests also cover 320px, 768px and 1440px and larger text. The screenshot in this folder uses a fake test guest.

## Artifacts

- Android: `build/app/outputs/flutter-apk/app-debug.apk` (185,894,656 bytes).
- APK SHA-256: `6ef9ba6de56c5e74bbe1f95dc12f8441ab6cfbeb1a7997c27fe9d29e55743c8b`.
- Web: `build/web/`.
- iOS: `ios/` source project; not built or signed on this Windows host.
- Fonts and licenses: `assets/fonts/`; verified in the APK and web asset output.

## Connections and limits

The Android debug artifact defaults to `http://10.0.2.2:8013/api/v1` for an Android emulator. A physical device must use the office server's reachable address in Server connection. The local web artifact defaults to `http://127.0.0.1:8013/api/v1` and was built with ALLOW_HTTP for local review. Rebuild production artifacts with HTTPS and omit ALLOW_HTTP.

The Android APK is a development build, not a Play Store release. Android/iOS identifiers, release signing and Apple team settings must be configured before store distribution. Actual Android hardware/emulator runtime testing and iOS testing/signing remain deployment verification steps; this Windows host has no connected Android device or Mac/Xcode.

SMTP/Twilio configuration and background workers remain necessary for actual guest delivery. Tests did not send real guest messages or modify live booking data. Arbitrary master-data setup remains in the Laravel administration/API as documented in API-MAPPING.md.

## Google Play bundle verification

The earlier APK/web notes above describe development artifacts. A separate production app-release.aab has now been built with the live HTTPS API, package com.learnwithzaman.coxbazarbanglo, version 1.0.0+1 and a new upload key. Target API 36, minimum API 24. Flutter analysis: no issues; 11 tests passed. Laravel: 50 tests / 242 assertions passed. Bundle signature verification succeeded; CRC and all nine native ELF libraries passed the 16 KB LOAD alignment check. See RELEASE-VERIFICATION.json for checksum and library details. Live DNS failed to resolve from this build environment; remote login, real-device execution and Play-delivered APK testing remain unverified. See PLAY-STORE-RELEASE.md before upload.

## Theme fix — 1.0.1+2

Appearance now updates before the preference API call and is persisted on the device. Failed sync retains the selection and queues its values for that account. Startup restores local appearance before network calls. Regression tests cover actual MaterialApp brightness while offline, restart persistence, and queued sync. Final Flutter analysis has no issues. No Laravel API change is required by this fix. Live server connection issues shown in the screenshot remain separate from local appearance.

Final theme-fix verification: 13 Flutter tests passed. Production web and signed Android AAB rebuilt successfully as 1.0.1+2; bundle signature, CRC and native ELF alignment rechecked.

## Final initial-release version correction

No AAB has been uploaded to Play Console. The initial release is therefore restored to versionName 1.0.0 and versionCode 1 (pubspec.yaml 1.0.0+1), retaining all tested theme fixes. Earlier references to 1.0.1+2 describe a superseded local build. Package ID, production API URL and upload signing key are unchanged.

The final initial-release AAB rebuilt successfully. Merged release manifest confirms versionName 1.0.0 / versionCode 1. Signature, archive CRC and native-library alignment verification passed; RELEASE-VERIFICATION.json contains the updated checksum.
