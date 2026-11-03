# Static purchase dashboard

The Dashboard destination now uses DashboardViewModel and DashboardRepository,
not the live PointOfPurchaseViewModel. StaticDashboardRepository is selected in
lib/core/di/dependency_injection.dart. It has no Dio, API client, or artificial delay.

The data models live in lib/features/dashboard/models/. DashboardData contains
product definitions, a transaction ledger, reporting period, currency symbol and
an explicit isDemo flag. Summary counts, amounts and product quantities are
calculated from that ledger so they cannot drift from one another. The eight demo
transactions total $24,500: Product A 120 kg / $14,500; Product B 80 kg / $10,000;
two drafts and six submitted transactions. Four recent entries are shown.

Only Copra is referenced in the current form; a complete two-product definition
is absent. Product A and Product B therefore remain explicit placeholders. The
existing dollar notation and kilogram units are retained, with no assumed INR
or currency conversion. All sample values live in StaticDashboardRepository.

The screen includes the shared logo header, greeting, demo notice, purchase value
and transaction count, compact status KPIs, both products, recent transactions,
and existing Add purchase / View purchases / View suppliers actions. Layouts
stack when phone width or text size needs more room. Navigation and the floating
navbar are unchanged. Demo records have no documentName and cannot open fake
ERP documents. API records can supply a real documentName to enable the existing
purchase-detail route.

To integrate APIs, implement DashboardRepository.getDashboardData(), map the ERP
response into DashboardData with isDemo false and the real period/currency, and
replace StaticDashboardRepository in dependency injection. No UI changes are
needed. This contract currently accepts a complete reporting-period transaction
set; a paginated backend must aggregate that full period before constructing the
model rather than passing only one page as a complete total.

The ViewModel supports loading, cached success, empty results, safe errors, retry,
refresh, in-flight deduplication and disposal. Refresh failures retain prior data.

Validation uses the existing phone/theme/text-scale matrix, repository consistency
and ViewModel lifecycle tests, and real-router quick action/back checks. No live
ERP mutations are used. Release APK compilation is checked; device rendering still
requires an Android device or emulator. Older dashboard density figures in
compact-ui-and-navigation.md describe the superseded live-list dashboard.
