# CML SI Buying

Flutter application foundation for an ERPNext/Frappe buying workflow. The project uses feature-first MVVM: views depend on Provider ViewModels, ViewModels depend on repositories, and repositories use the shared Frappe API clients.

## Setup and run

1. Install the Flutter stable SDK and run `flutter pub get`.
2. Set `FRAPPE_BASE_URL` in `.env.example` to your ERPNext site URL. This example file is bundled so the app can load it with `flutter_dotenv`. The URL is configuration, not a secret; never add API keys or passwords to the Flutter bundle.
3. Run `flutter run` for the connected device, or specify a target such as `flutter run -d chrome`.

The app starts on the splash screen, validates any persisted session, and redirects to sign-in when no valid session exists. Sign-in uses Frappe's cookie session. Cookie files are persisted in the application support directory on native platforms. The example URL is a placeholder, so requests need a configured reachable Frappe site.

## Packages

- `provider` for ChangeNotifier ViewModels
- `dio`, `cookie_jar`, and `dio_cookie_manager` for HTTP and persisted Frappe sessions
- `go_router` for protected navigation
- `flutter_secure_storage` for session state
- `shared_preferences` for simple local preferences
- `flutter_dotenv` for environment configuration

## API examples

```dart
final customers = await resourceApi.getDocList(
  'Customer',
  fields: ['name', 'customer_name'],
  limitPageLength: 10,
);

final loggedInUser = await methodApi.callGetMethod(
  'frappe.auth.get_logged_user',
);
```

The Resource API serializes filters and fields, encodes DocType and document path segments, and normalizes the Frappe `data` envelope. The Method API keeps dotted Python method paths intact and unwraps `message` by default; pass `preserveResponse: true` for the complete envelope. Dashboard customer access is optional: if the account lacks Customer permission, the logged-in user still appears and the customer card reports that the data is unavailable.

## Adding a feature

Create `models/`, `repositories/`, `viewmodels/`, `views/`, and `widgets/` under `lib/features/<feature>/`. Keep UI behavior in the ViewModel, API mapping in its repository, and reuse `FrappeResourceApi` or `FrappeMethodApi` through constructor injection. Register the ViewModel and protected route in the app composition and router.

## Validation

```shell
dart format lib test
flutter analyze
flutter test
```

The API tests use a mocked Dio adapter and do not require an ERPNext server.
