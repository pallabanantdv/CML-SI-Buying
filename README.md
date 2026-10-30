# CML SI Buying

Flutter application foundation using feature-first MVVM, Provider + ChangeNotifier, Dio, GoRouter, and Material 3.

## Run

1. Set `FRAPPE_BASE_URL` in the bundled `.env.example` file to your ERPNext site.
2. Run `flutter pub get`.
3. Run `flutter run` (or `flutter run -d chrome`).

Unauthenticated users start at Splash and are redirected to Login. The existing Frappe cookie-session login remains in place. After login, GoRouter opens Dashboard inside the four-branch navigation shell.

For module UI preview, `AppConstants.bypassLoginForModulePreview` in `lib/config/constants/app_constants.dart` is currently `true`. Set this single flag to `false` to restore Splash, session validation, and Login gating.

## Main modules

The mobile navigation contains Dashboard, Purchase, Supplier, and Profile. `StatefulShellRoute.indexedStack` keeps independent tab stacks; GoRouter owns selected-tab state. Dashboard, Point of Purchase, and Add Supplier show neutral placeholders until their requirements are defined. They have repository and ChangeNotifier ViewModel foundations but make no module API calls. Profile preserves local theme selection and sign-out without fetching ERPNext profile data.

The debug-only component showcase remains at `/design-system` and is not part of the four main tabs.

## Structure

- `lib/config/routes/`: centralized route names and paths, protected route redirects, and the four shell branches.
- `lib/config/theme/`: centralized light/dark colors, semantic ThemeExtension, typography, spacing, dimensions, Material themes, and persisted theme selection.
- `lib/core/`: shared networking, storage, errors, utilities, and dependency composition.
- `lib/shared/navigation/`: `MainShell`, GoRouter-backed bottom navigation, and item model.
- `lib/shared/widgets/`: reusable design-system components.
- `lib/features/`: auth, dashboard, point of purchase, supplier, and profile modules.

Add feature models, widgets, and API mappings once that module's requirements are known. Keep UI interactions in its ViewModel and module data access in its repository.

## Validation

```shell
dart format lib test
flutter analyze
flutter test
```
