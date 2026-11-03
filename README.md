# CML SI Buying

Flutter application for CAML SI Buying, built with feature-first MVVM, Provider, Dio, GoRouter, and Material 3.

## Run locally

Install the Flutter SDK and Android toolchain, then run:

```shell
flutter pub get
flutter run --dart-define=FRAPPE_BASE_URL=https://your-erpnext-domain.com
```

`.env.example` is a safe template only. Use a real ERPNext URL for local runs. Release builds read `FRAPPE_BASE_URL` only from a Dart define and never load the development environment file.

## Build a signed Android release APK

The Android application ID is `com.caml.si.buying`. Confirm this is the organization’s permanent ID before publishing; changing it after publishing creates a separate app.

1. Set the ERPNext base URL to the production HTTPS endpoint.
2. Generate an upload keystore. Keep the passwords private and back up the keystore securely:

   ```shell
   keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

3. Copy `android/key.properties.example` to `android/key.properties`, then set the real store password, key password, alias, and keystore path. The properties file and keystore are excluded from Git.
4. Set the release version in `pubspec.yaml` (`version: name+buildNumber`), then build:

   ```shell
   flutter build apk --release --dart-define=FRAPPE_BASE_URL=https://your-production-erpnext-domain.com
   ```

The signed APK is written to `build/app/outputs/flutter-apk/app-release.apk`. Gradle stops release packaging if a valid local release keystore is not configured; it never signs a release APK with the debug key. To build an Android App Bundle for Play Console, use `flutter build appbundle --release` with the same Dart define.

The Android manifest includes Internet permission. Do not use an HTTP endpoint for a production build; Android blocks cleartext network traffic by default.

## Project structure

- `lib/config/` contains routes, theme, environment, and app constants.
- `lib/core/` contains networking, storage, errors, and dependency injection.
- `lib/features/` contains auth, dashboard, point of purchase, profile, and supplier modules.
- `lib/shared/` contains navigation and reusable UI components.

Login is enabled. `AppConstants.bypassLoginForModulePreview` must remain `false` for release builds.

## API and loading diagnostics

Debug builds log automatically. Production release logging is off by default.
Use the real HTTPS ERPNext URL (release does not load `.env`):

```shell
flutter run --release --dart-define=FRAPPE_BASE_URL=https://your-server --dart-define=ENABLE_API_LOGS=true
flutter build apk --release --dart-define=FRAPPE_BASE_URL=https://your-server --dart-define=ENABLE_API_LOGS=true
adb logcat -v time flutter:I "*:S"
```

Look for `[CAML]`: API events include a request ID, UTC timestamps, method,
redacted URL/query/headers/body, timeouts, status, elapsed milliseconds, and
error type/stack frames. Output is split into 700-character chunks. Payload
structure remains visible but scalar values, including error text and business
records, are redacted. Resource document names and URL credentials are omitted.
Never enable an unredacted Dio logger alongside this interceptor.

For each affected screen, follow `initState`, `list/detail load started`, API
request/response/error, `parsed count` / `detail parsed`, `notifyListeners`, and
`render loading=false`. A request failure should instead end with an error and
`loading=false`; Retry starts a new request. A missing base URL now returns an
explicit configuration error before Dio runs.

## First-load investigation

The three screens previously invoked methods that synchronously notify an
ancestor Provider from `initState` (and detail `didUpdateWidget`), during tree
construction. Initial loads now start after the first frame with a mounted
check; this is a lifecycle boundary, with no timer or forced rebuild. Completion
continues through the existing Consumer subscriptions. The shell now keeps the
same Offstage/TickerMode/transition ancestry as branches change visibility.
List loads reject overlapping requests; detail loads also deduplicate the same
in-flight document and ignore obsolete responses. Disposed list/detail models
ignore late results and notifications.

The app-scoped models already retained response data across navigation, so a
later rebuild can display that data even when the initial update was missed.
This explains the reported symptom in principle, but does not prove its exact
release-only trigger. No Android device was connected during this investigation;
the original debug/release divergence and production API behavior remain to be
confirmed using the diagnostic sequence above. Do not attribute the issue to
optimization, shrinking, or a missing notifyListeners without device evidence.

Other checked paths: bootstrap awaits dependency creation; authentication awaits
login/session restoration and cookies; GoRouter guards authenticated routes;
Internet permission is in the main manifest; Dio uses finite timeouts. Release
requires FRAPPE_BASE_URL, whereas debug can read dotenv. That configuration
difference cannot explain data appearing on a second visit by itself.

Regression tests in `test/loading_lifecycle_test.dart` exercise first-visit list
and detail rendering, delayed responses, supplier errors/retry, overlapping and
obsolete detail requests, disposal, branch identity, and sensitive-data redaction.
Fresh installation, app restart, real backend errors, release timing, and Android
logcat visibility require verification on a connected Android device.

Verification performed on 2026-11-03:

- `flutter test --reporter compact`: all 18 tests passed;
  `flutter test test/loading_lifecycle_test.dart`: all 6 lifecycle tests passed.
- `flutter analyze`: 4 existing findings in unchanged code (unused imports in
  app_constants/dashboard and null-aware element style in the create purchase screen).
- `flutter build apk --release`: passed (56.7 MB APK). This compile check did not
  supply a backend URL; rebuild with the real FRAPPE_BASE_URL before installation.
- `flutter devices`: Windows/Chrome/Edge only; no Android target connected.
- `flutter build apk --release --dart-define=ENABLE_API_LOGS=true`: passed
  (56.8 MB APK). This diagnostic variant is currently at
  `build/app/outputs/flutter-apk/app-release.apk`; it also needs a real backend
  URL supplied on rebuild before it can contact ERPNext.

## Mobile interface

The approved mobile redesign is implemented across the dashboard, purchases,
suppliers, forms, profile, and authentication screens. See
[the implementation and verification notes](docs/mobile-redesign.md) for component
changes, data limits, test coverage, and device verification requirements.

Run `flutter test --reporter expanded` to regenerate the responsive screen previews
in `build/mobile-previews/`. Production screens use the existing Frappe repositories;
preview fixtures are confined to the tests.

The compact-density and floating-navbar follow-up is documented in
[compact UI and navigation notes](docs/compact-ui-and-navigation.md), including
measured card-height reductions, safe-area behavior and validation coverage.
