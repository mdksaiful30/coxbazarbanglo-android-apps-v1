# Google Play release — Cox Banglo

New app package: com.learnwithzaman.coxbazarbanglo
Android version: 1.0.2 (versionCode 3), configured by pubspec.yaml 1.0.2+3. This release fixes past-day booking creation and generates PDF/JPG booking summaries locally in Flutter.
API: https://coxbazarbanglo.learnwithzaman.com/api/v1
Target Android API: 36; minimum API: 24 (Android 7).

## Files to upload / keep

Upload releases/coxbazarbanglo-1.0.2-3-booking-fixes.aab to Play Console. The same bundle is also available at build/app/outputs/bundle/release/app-release.aab. The older releases/coxbazarbanglo-1.0.0-1.aab is an unbranded backup; use the latest file with -booking-fixes in its name. Never upload the keystore or key.properties to hosting, Play listing assets, or source control. Back up android/upload-keystore.jks AND android/key.properties securely outside this computer; the latter contains the generated passwords. android/upload-certificate.pem is the public certificate, not the private key. Release signing deliberately has no debug-key fallback.

## Restricted membership

Only existing active admin/staff accounts can sign in; users cannot register themselves. For selected Google accounts to install, create a closed testing track with an email list or Google Group and share its opt-in link. A production listing can still require membership to log in, but does not itself restrict who can download. If your organization uses managed Google Play, evaluate a private organizational app instead. A closed test is not a permanent private production distribution solution; follow the account-specific production testing requirements displayed in Play Console.

Create the app in Play Console; enroll in Play App Signing; select the closed testing track; add authorized testers; upload the signed AAB; complete the store listing, content rating, target audience, ads declaration, public privacy-policy URL and accurate Data safety answers. Account access and guest records/documents must be reflected in those answers. Do not claim no data collection: the app sends account and booking information to your server.

In App content > App access, declare restricted access and provide a working reusable reviewer login with English instructions. Prepare a dedicated review account and suitable demonstration data rather than disclosing your own admin password. A reviewer must be able to inspect the necessary features. No reviewer account has been created automatically.

## Server deployment and test before release

Deploy the Laravel changes listed in its docs/API-VERSIONING.md to Hostinger, preserving .env/APP_KEY. Run php artisan optimize:clear, php artisan config:cache and php artisan route:cache. No migration is required by the versioning changes. Verify HTTPS /api/v1/version returns release metadata and /api/v1/auth/me returns JSON 401 without credentials. Then test login, a permitted booking flow, exports and logout on a real Android device through the testing track. Production DNS/login could not be verified from the build environment; resolve any DNS or hosting errors before submitting.

Release mode uses the compiled production server and hides the development server selector. Tokens saved for another server are discarded. For local debug development use flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8013/api/v1 (HTTP remains subject to the existing debug configuration).

## Build subsequent releases

For the next release after uploading this bundle, increment pubspec.yaml to 1.0.3+4, then continue increasing the number after + for every Play upload. Preserve the package ID and signing key. Run flutter analyze, flutter test and:

flutter build appbundle --release --dart-define=API_BASE_URL=https://coxbazarbanglo.learnwithzaman.com/api/v1

Laravel application release 1.2.0 and API contract v1 are independent of Android's versionCode. Breaking API changes need a parallel v2 and a deliberate client migration; keep v1 for older installed apps.

## References

https://docs.flutter.dev/deployment/android
https://developer.android.com/google/play/requirements/target-sdk
https://support.google.com/googleplay/android-developer/answer/15748846


