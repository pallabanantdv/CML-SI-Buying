# CAML SI Buying mobile redesign

Implemented after approval of the screen-by-screen plan on 2026-11-03.

> Follow-up: compact spacing, card layouts and floating navigation now supersede
> the original sizing below. See [compact UI and navigation](compact-ui-and-navigation.md)
> for the current implementation and measured density improvements.


## Presentation and navigation

- Centralized 16 dp page gutters, 12-16 dp card spacing, 52 dp controls,
  rounded surfaces, Inter body text and Poppins headings.
- Preserved the CAML logo-derived blue/green palette; refined semantic colors
  and dark-theme foregrounds for readable contrast. Theme tests require 4.5:1
  contrast for primary/secondary text and status labels on their tinted surfaces.
- Four labelled destinations retain the original GoRouter routes and arguments.
  Purchase creation is a labelled action on Dashboard/Purchases. Nested back
  navigation returns to the list; system back from a branch root returns home.
- Initial screen loads remain after the first frame. A shared read-through
  purchase cache avoids a second dashboard/list request and clears on account
  changes; obsolete responses cannot refill the cleared purchase cache.
- Short card entrances and status-color transitions respect reduced motion.

## Screens

| Screen/file | Result |
|---|---|
| dashboard_screen.dart | Greeting, primary actions, summaries and three recent purchases from the existing purchase ViewModel |
| point_of_purchase_screen.dart | Local search/status filters, readable cards, explicit dataset limit, refresh/retry and create action |
| point_of_purchase_detail_screen.dart | Summary, supplier, financial totals, expanded items and collapsible secondary metadata; all returned fields remain accessible |
| add_supplier_screen.dart | Supplier directory with full-width search, distinct creation action and simplified cards |
| create_supplier_screen.dart | Grouped identity/location/contact inputs, original defaults and validation, keyboard-aware Save supplier action |
| create_point_of_purchase_screen.dart | Existing editable rows/calculations in readable sections, reachable save action and visible failure feedback |
| profile_screen.dart | Identity header, grouped account information, existing roles/appearance/sign-out actions |
| login_screen.dart / login_form.dart | Fluid spacing, keyboard-friendly form and password keyboard submission |
| splash_screen.dart | Existing authentication and animation sequence retained; content scrolls on short displays |
| design_system_screen.dart | Updated typography/components and mobile search/summary examples |

## Shared components

Existing AppCard, AppAppBar, AppHeaderTitle, AppButton, AppTextField, AppDropdown,
AppStatusBadge, AppPageBanner, AppSnackbar and state widgets are reused. Added:
AppSearchField, AppSummaryCard, AppFormActionBar, AppExpandableSection,
AppEntrance, AppStateLayout and the feature-specific AppPurchaseCard.

Forms keep every field mounted so FormState validates fields below the viewport.
The first invalid field is scrolled into view. Programmatically supplied dropdown
values (such as the item's UOM) synchronize their displayed and validated value.
Payload keys, validation rules and purchasing formulas are unchanged.

The repositories, API contracts, authentication rules and production data sources
were preserved. No packages were added. UI preview data exists only in tests.

## Data boundaries

Purchases remain limited to the latest 50 records and suppliers to the most
recently updated 100. Search/status filters apply to those records. Dashboard
summaries explicitly describe this recent dataset; they are not organization-wide
metrics. No approval, notification, payment or pagination API was invented.

Orientation remains available. Portrait and landscape layouts are checked;
there is no forced portrait lock or platform manifest orientation change.

## Verification

- dart format applied to changed/new Dart files.
- flutter analyze: no issues.
- flutter test --reporter expanded: 33 tests passed, including existing lifecycle,
  authentication, Frappe networking and diagnostic-redaction regressions.
- 128 portrait layout combinations: eight main screens at 320/360/390/430 dp,
  text scales 1x/2x, and light/dark themes, with long names and large amounts.
- Additional landscape/large-text checks, bounded loading/empty/error states,
  supplier keyboard/validation, purchase search/status filters, cache reuse,
  tab/system-back navigation, supplier submission payload, purchase calculations,
  item payload and API rejection feedback.
- flutter build apk --debug: passed.
- flutter build apk --release: passed.

Tests generate individual screen previews under build/mobile-previews/ and a
full-suite execution log at build/final-tests.log. Previews use test fixtures;
the running application continues to use Frappe. Standalone screen previews do
not include the shell's bottom navigation; navigation has its own router test.

## Device checks still required

No real Android/iOS interaction or live ERP mutations were performed. iOS builds
require macOS/Xcode. Fresh installation, actual keyboard/IME behavior, native
accessibility services and real backend permissions should be checked on devices.
The APK compilation checks omit FRAPPE_BASE_URL; release still requires the real
HTTPS endpoint via --dart-define before it can contact ERPNext. Existing diagnostic
logging remains controlled by ENABLE_API_LOGS and disabled by default in release.

Typography update: Alike Angular now replaces Inter for body text, labels, fields and buttons. Poppins headings remain. The font and SIL license are bundled locally; no runtime font download is needed.
