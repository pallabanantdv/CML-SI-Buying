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
