# Supplier HTML print preview

Supplier Details keeps its existing information sections and offers a **Print
Preview** button in the supplier-card section. Opening details does not fetch
the print format. The button calls `SupplierViewModel.loadPrintPreview`, which
deduplicates requests and rejects results from a previous login session.

The existing authenticated Dio client calls `/printview` with `doctype=Supplier`,
the selected supplier's name, `format=Card front 2`, and `no_letterhead=1`.
`HtmlPrintDocument.extractHtml` accepts the actual raw HTML response as well as
Frappe `message` and `message.html` wrappers. It rejects invalid/empty content
and recognized login pages, wraps fragments, and adds a viewport only when the
document does not already have one. Existing print CSS is preserved.

GoRouter passes the fetched document in memory to the reusable
`HtmlPrintPreviewScreen`. The preview does not repeat the HTML API request.
Refresh reloads that same HTML. Return to details and tap Print Preview again
to fetch a new server version.

The official `webview_flutter` controller uses `loadHtmlString` with the configured
ERP server's `/printview` base URL. Relative CSS, fonts, and image URLs therefore
resolve against that server. Session cookies are copied from the existing Dio
cookie jar to the native WebView cookie manager; credentials are never appended
to asset URLs. JavaScript is disabled, main-frame navigation outside the loaded
document is blocked, and native scrolling and zoom remain enabled. Failed
subresources do not replace the entire document with an error state.

The preview uses a white document surface, application app bar, skeleton loading,
load progress, retry, and a rendering timeout. Native platform views own their
disposal; callback generation checks and timer cancellation prevent late updates.

Print and Save/Share PDF are separate optional actions. They request the actual
server-generated PDF using the existing authenticated Frappe PDF endpoint, with
the same supplier, format and no-letterhead setting. The `printing` plugin hands
the resulting PDF to the system print/share flow. This does not convert or rename
HTML to PDF. ERP PDF generation must be configured; if it fails, the HTML preview
stays available and its error is reported separately.

The official WebView supports Android, iOS and macOS. Windows, Linux and web show
an explicit unsupported HTML-preview message; PDF toolbar actions remain available
where the platform printing plugin supports them. The older InAppWebView plugin
was removed because its Android module fails with this project's Gradle version.

## Files

- `lib/core/models/html_print_document.dart`: document arguments and HTML parsing.
- `lib/core/widgets/html_print_preview_screen.dart`: reusable document viewer.
- `lib/core/network/api_client.dart`: existing HTML transport uses the parser.
- `lib/core/network/frappe_resource_api.dart`: preserves printview request and
  matches PDF no-letterhead settings.
- `lib/features/supplier/viewmodels/supplier_viewmodel.dart`: print request state.
- `lib/features/supplier/views/supplier_details_screen.dart`: guarded navigation.
- `lib/features/supplier/widgets/supplier_print_card.dart`: preview action/state.
- `lib/config/routes/app_router.dart`, `route_names.dart`: GoRouter preview route.
- `pubspec.yaml`, `pubspec.lock`, generated registrants: official WebView and
  printing dependencies.
- `test/html_print_preview_test.dart`, `test/supplier_details_test.dart`: parsing,
  lifecycle, request, and navigation checks.
- `docs/testing/html_print_preview_test.dart.example`: optional native styled
  document smoke test. Restore it under `integration_test/` and enable the Flutter
  `integration_test` SDK dev dependency before running on a device. The dependency
  was disabled in the workspace during validation; the example is not analyzed
  as application code.
- `macos/Runner/*.entitlements`: native printing and network client access.

Native rendering, scrolling, zoom, real asset authentication, printer dialogs and
iOS compatibility require a device test against the ERP server. Widget tests do
not establish browser layout equivalence or live server availability.

Validation: 21 supplier/API/preview unit and widget tests passed. The full
`flutter analyze --no-pub` run reports the pre-existing unused
`_erpFieldsSection` warning in the purchase form. Changed feature files analyze
without issues. Native and release runtime behavior are not verified: the device
test could not compile after its SDK test dependency was disabled, and release
validation encountered regenerated/removed Flutter build artifacts. The initial
legacy WebView Gradle incompatibility was removed with the legacy plugin.
