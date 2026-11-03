# Compact UI and floating navigation

## Causes found before changes

Purchase cards stacked separate date/weight facts, a divider and an amount band.
Supplier cards added a separate status row, a 40 dp avatar and a divider around
contacts. Profile identity used a standalone 60 dp avatar; each account field
stacked its label above its value. KPI icons had a row and 16 dp gap to themselves.
Repeated editor rows nested cards inside cards. Shared cards used 16 dp padding,
16 dp corners, 44 dp leading badges and large section gaps. Controls were 52 dp.

## Compact layouts

- Shared card padding is 12 dp with 12 dp corners; list gaps are 8 dp and section
  gaps 12 dp. Existing 16 dp page gutters remain. Large spacing tokens are retained
  for situations that need them rather than globally reducing every spacing value.
- Purchase number is primary; status aligns to the trailing edge. Supplier and
  secondary facts follow with date/net amount sharing a row when there is room.
  Full secondary facts remain available through tooltips and the detail route.
- Supplier names/status share a header. Type/group/location and contacts no longer
  need an avatar or decorative divider band. Search, count and creation action
  use a compact responsive header.
- Details/profile use shared AppInfoRow/AppInfoGrid widgets for inline facts and
  two columns on wider layouts. Large text switches to stacked full-value layouts.
  Header email/status are no longer repeated in profile account details.
- KPI value and icon share a row. Dashboard quick actions sit side by side when
  readable; smaller phones and larger text retain stacked buttons.
- Forms retain all fields, validators, focus/keyboard behavior and safe-area save
  actions. Repeated editors are grouped rows instead of nested cards; remove
  actions remain available as labelled 48 dp icon buttons.
- Controls use 48 dp minimum targets. Decorative icons/badges are smaller, while
  interactive chips, buttons, expansion headers and navbar tabs retain touch space.

## Floating navigation

The latest targeted replacement was based on visual inspection of the supplied
Deverust image (downloaded to build/nav-reference/reference.png), alongside its
[Dribbble page](https://dribbble.com/shots/26779900-Floating-App-Navigation-Concept).
The image has an icon-only capsule, a dot under the active icon, and a circular
plus action joined through a curved neck. Its action sits at the right edge.
This app deliberately centers the action as requested, with two destinations on
each side. It uses CAML surface/primary colors instead of the reference's purple.

AppFloatingBottomNavigation draws a custom Material silhouette with curved necks
and a circular orbit around a 56 dp New purchase action. Content height is 68 dp,
side margins 16 dp, bottom gap 12 dp plus SafeArea. Icons are 23 dp, with a 5 dp
active dot, 220 ms color/indicator transitions, native ink feedback and reduced
motion support. Icon-only presentation stays compact at large text sizes; every
action retains its semantic label and tooltip. All touch targets exceed 48 dp
at the tested phone widths. The shadow uses Material elevation, not a border.

AppBottomNavigation still supplies the same four StatefulShellRoute destinations
and uses the original goBranch/reselection behavior. The plus action opens the
existing named createPointOfPurchase route and shows the existing success message
when a purchase is saved. The route itself manages saving and data updates.

The complete footprint remains reserved by Scaffold.bottomNavigationBar. No
content is covered. Router paths, authentication, Providers, API calls and business
rules were not changed for this navbar replacement. Tests cover branch selection,
nested details, Android back, creation/back, and the shared first-load cache.

## Measured density

Same data, fonts, 390 x 844 dp standalone screen viewport, 1x text scaling, light
theme. Values below are actual first-card heights in dp, not fixed layout heights.

| Card | Before | After | Reduction |
|---|---:|---:|---:|
| purchases | 228 | 133 | 42% |
| supplier | 223 | 165 | 26% |
| detail | 183 | 117 | 36% |
| profile | 216 | 105 | 51% |
| dashboard | 113 | 67 | 41% |

The purchase list shows four complete cards instead of two in this standalone
viewport. These comparisons exclude the navigation shell; they isolate screen
layout changes. Actual device system bars and the navigation shell reduce the
available content area. Source measurements and before/after screenshots are in
build/compact-density/{before,after}/. Cards remain content-driven and can grow
for long values or accessibility settings.

## Files changed in this scope

- config/theme/app_dimensions.dart, app_spacing.dart, app_text_styles.dart and
  app_theme.dart: compact component tokens and typography.
- shared/widgets/app_card.dart, app_card_heading.dart, app_info_row.dart,
  app_summary_card.dart, app_status_badge.dart, app_expandable_section.dart,
  app_search_field.dart, app_form_action_bar.dart and app_app_bar.dart.
- shared/navigation/app_floating_bottom_navigation.dart (new) and
  app_bottom_navigation.dart (existing shell adapter).
- point_of_purchase/widgets/app_purchase_card.dart and its list/detail/create
  screens; supplier directory/create screens; profile/dashboard screens;
  login screen/form and the component showcase.
- test/card_density_test.dart (new), bottom_navigation_test.dart,
  design_system_test.dart and mobile_ui_test.dart: measurements, navbar geometry,
  safe areas, touch targets and real-router selection/deep-link checks.

## Verification and limits

- dart format and flutter analyze: clean.
- Full suite: 36 tests passed, retaining loading/retry, auth, Frappe parsing,
  diagnostic redaction, form payload/calculation and navigation regressions.
- Existing screen matrix: eight screens at 320/360/390/430 dp, 1x/2x text and both
  themes (128 combinations), plus landscape and keyboard checks.
- Navbar matrix: four widths, three text scales, two themes and 0/34 dp bottom
  safe areas (48 combinations), selecting all four destinations in each case.
  Tests check 48 dp targets, content clearance, selection and absence of overflow.
- Real-router test includes Profile, direct purchase-detail route selection,
  branch-preserving tab changes, system back and successful supplier submission.
- Android debug and release APK builds passed. No real Android/iOS run or live ERP mutations were performed.
  iOS compilation needs macOS/Xcode. Release API use still requires the real HTTPS
  FRAPPE_BASE_URL define; these compilation checks omit a backend URL.

Navbar previews: build/mobile-previews/floating-nav-light.png and
floating-nav-dark.png. Tests use fixtures only; production data sources are unchanged.

