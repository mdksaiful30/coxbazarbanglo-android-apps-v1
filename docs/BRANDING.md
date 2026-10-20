# Shared Coxbazarbanglo branding

Updated on 19 October 2026 using the existing generated logo from the Laravel application.

The bundled assets in `assets/brand/` are available offline. `lib/widgets/brand_logo.dart` provides the full logo and compact symbol with an accessible label and a white backing for both themes. Sign-in, startup, navigation and the mobile app bar use this widget.

Android has legacy and round launcher icons for all densities, adaptive icons for Android 8+, monochrome icons for Android 13+, and a branded launch background. The package ID and upload key are unchanged. iOS icon and launch-image sources are updated, but an iOS archive requires macOS/Xcode. Flutter web has a new favicon plus regular and maskable install icons.

The initial release remains **1.0.0+1** at the user's request because the earlier AAB was never uploaded to Play. Upload `releases/coxbazarbanglo-1.0.0-1-branded.aab`. `releases/coxbazarbanglo-1.0.0-1.aab` preserves the earlier unbranded artifact. The 512px opaque listing icon is `releases/play-store-icon-512.png`.

Checks passed: Flutter analysis, all 17 tests (including phone/desktop branding in light/dark themes), signed Android release build, bundletool 1.18.3 validation, ZIP integrity, embedded logo hashes, package/version values in the bundle, upload certificate match, and 16KB-or-greater native ELF LOAD alignment. The production Flutter web build passed and its favicon matches the source. No physical-device or Play Console upload test was performed.

The production API remains `https://coxbazarbanglo.learnwithzaman.com/api/v1`. See `RELEASE-VERIFICATION.json` for the artifact size, checksum, and certificate fingerprint. No credentials or signing keys belong in a store upload.
