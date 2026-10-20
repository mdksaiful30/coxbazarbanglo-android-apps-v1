# Cox Banglo

Native Flutter staff/admin client for the existing Laravel rest-house API. Android, iOS and web share one codebase. This is a native widget application, not a WebView wrapper. Laravel remains the authority for approvals, room conflicts, quotes, invoices and access control.

## Start locally

From this folder:

```powershell
flutter pub get
# In another terminal, start Laravel from its existing folder:
# php artisan serve --host=127.0.0.1 --port=8013
flutter run -d chrome --web-port 8085 --no-web-resources-cdn --dart-define=API_BASE_URL=http://127.0.0.1:8013/api/v1
```

Sign in with an existing Laravel admin/staff account. No credentials are embedded. The login screen's **Server connection** section can change the API address. Never enter MySQL credentials in this app.

Android emulator: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8013/api/v1`. For a physical Android/iOS device, use your development computer's LAN address and run the local Laravel server with `--host=0.0.0.0` only on a trusted development network. Release deployments require an HTTPS server.

Flutter web development uses port **8085**. Laravel `config/cors.php` permits the explicit localhost/127.0.0.1 origins at that port. For a deployed website, set `FLUTTER_WEB_ORIGINS=https://app.your-domain.com` in the Laravel environment and refresh its config cache. Bearer requests do not use browser session cookies.

## Included workflows

- Mobile/tablet/desktop navigation, scrollable calendar, responsive field grids, keyboard-safe full-screen phone editors and bounded desktop dialogs.
- Sign-in, secure token persistence, session restore, expiry handling, password recovery/reset, password changes, logout and device revocation.
- Dashboard, searchable/paginated bookings and guests, date-specific availability and seven-day room calendar.
- Guest registration/editing, booking drafts, category/tariff selection, rooms, reference letters, guest count, designation/contact details and server-generated quotes.
- Staff submission and amendment proposals; admin confirmation, rejection/return, cancellation, no-show, check-in/out, amendment decisions and editing approved booking details.
- Booking room number and Bengali name, financial balances, verified payments, refunds, reversals and credit notes. History remains server-managed.
- Server PDF/JPG generation, device download/save, native file share sheet, WhatsApp/email text composers, provider-based queued delivery and delivery history.
- Private reference file uploads/downloads (PDF/JPG/PNG, maximum 5 MB).
- Admin room capacity/readiness, fixed-time reservations and maintenance, tariff cloning/rate edits/authorized activation, staff administration, CSV reports, notifications/retry and audit records.
- Light/dark/system theme and English/Bengali navigation synced to account preferences. The interface includes English operational labels; full Bengali translation is not claimed.
- Offline-bundled Roboto and Noto Sans Bengali fonts, and the requested typography hierarchy.
- Footer: Developed by Zaman's Dev.

The app requires an online API; it does not approve bookings or record payments offline. Notifications still need the existing backend's SMTP/Twilio configuration, scheduler and queue worker. A successful queue request is not delivery confirmation. Native sharing opens a user-confirmed composer. Browser download/share behavior depends on available browser/platform support.

## Build

```powershell
# Development Android APK (local emulator API)
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8013/api/v1
# Production Android: release ID and local upload signing are configured
flutter build appbundle --release --dart-define=API_BASE_URL=https://coxbazarbanglo.learnwithzaman.com/api/v1
# Production web; renderer assets are served locally
flutter build web --release --no-web-resources-cdn --dart-define=API_BASE_URL=https://coxbazarbanglo.learnwithzaman.com/api/v1
# iOS: run on macOS with Xcode, then configure Apple team, bundle ID and signing
flutter build ios --release --dart-define=API_BASE_URL=https://coxbazarbanglo.learnwithzaman.com/api/v1
```

The local web review build may be generated with `--dart-define=ALLOW_HTTP=true` against localhost. That flag is for development artifacts only; omit it from production builds. Android cleartext HTTP is allowed only in the debug manifest. The iOS project allows local networking, not arbitrary insecure production endpoints. Web secure storage requires HTTPS or a localhost secure context.

Android output: `build/app/outputs/flutter-apk/app-debug.apk`. Web output: `build/web/`. An iOS archive cannot be built or signed on this Windows host; the iOS source project is included for a Mac/Xcode build. Generated package identifiers still use the Flutter starter namespace; choose organization-owned identifiers before store publication.

## Understand and maintain the code

- `lib/main.dart`: entry point and themed application.
- `lib/core/api.dart`: REST client, errors, authentication headers and uncertain-request idempotency.
- `lib/core/session.dart`: account/session and preference state.
- `lib/core/theme.dart`: shared colors, typography and bundled fonts.
- `lib/features/shell.dart`: adaptive navigation and page selection.
- `lib/features/bookings/`: list, validated editor and details/finance/sharing.
- `lib/features/overview.dart`: dashboard, rooms and calendar.
- `lib/features/directory.dart`: guests, reservations, tariffs, staff, reports and operational history.
- `lib/features/account.dart`: appearance, password and device sessions.
- `lib/widgets/`: reusable panels, dialogs, fields, status chips and formatting.
- `docs/API-MAPPING.md`: screen-to-endpoint map and integration rules.

```powershell
flutter analyze
flutter test
G:\flutter\bin\cache\dart-sdk\bin\dart.exe format lib test
```

Use the Dart SDK bundled with Flutter. Another standalone Dart SDK is also installed on this computer, so use `flutter` or the explicit bundled path when tooling differs. Tests use fake API fixtures; real integration checks use only the backend's disposable test database.

Current platform baselines: Android API 24+ and iOS 15+.

## Ready artifacts and verification

The Android debug APK is in `build/app/outputs/flutter-apk/app-debug.apk`. The local web review build is in `build/web/`. Detailed test results, artifact checksums, server configuration and remaining store/device checks are in `docs/VERIFICATION.md`. The checked phone preview is `docs/flutter-phone.png`.

Font license notices are bundled in the generated app assets alongside Roboto and Noto Sans Bengali. The app uses the shared Coxbazarbanglo bungalow-and-wave logo, Android adaptive/legacy/themed launcher icons, iOS icons and web favicon. See docs/BRANDING.md.

## Google Play release

Production API is the default. Android package: com.learnwithzaman.coxbazarbanglo; version: 1.0.0+1. See [release instructions](docs/PLAY-STORE-RELEASE.md) for restricted membership, signing backups, Hostinger deployment and future versions. Release mode hides the development server selector.

