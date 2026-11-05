# Offline-first data caching

## Project analysis and implementation plan

The existing app uses Provider view models, repositories, a shared ApiClient with Dio, Frappe resource/method wrappers, persisted session cookies, flutter_secure_storage, SharedPreferences, GoRouter, and SkeletonReveal/loading skeletons. The dashboard repository is static demo data; it has no server endpoint. Supplier creation uses static form choices. Purchase and supplier lists, purchase details, purchase-form references/advances, and the profile/roles are API-backed.

The implementation follows this plan:

1. Reuse the existing transport and encrypted storage rather than introduce a second networking stack or database dependency.
2. Add a policy-controlled cache below existing repositories so response parsing and repository APIs remain compatible.
3. Return saved responses immediately; deduplicate background revalidation; publish changed endpoints to the existing Provider composition.
4. Preserve content and scrollable identity during refresh, and retain skeletons for uncached initial loads.
5. Restore only previously authenticated local identities, scoped to the configured server; reset all user-specific in-memory state on account transitions.
6. Detect interface changes and actual Dio failures separately; refresh after reconnect/resume; block offline server mutations.
7. Test persistence, isolation, freshness, invalidation, concurrency, failure fallback, and existing UI behavior, then compile a release APK.

Existing uncommitted navigation, purchase-form, skeleton and styling changes were preserved. This document lists files touched for the offline work only.

## Architecture and storage

Views still use their Provider view models. Repositories still parse Frappe responses through FrappeResourceApi/FrappeMethodApi. Their shared ApiClient delegates reviewed GET requests to CacheManager. CacheService owns persistence. ConnectivityService owns network state; Dio outcomes determine whether a connected interface can actually reach the server.

CacheService reuses **flutter_secure_storage**, the app's existing encrypted persistent storage. A JSON snapshot is stored separately from session markers and identity metadata. This avoids an additional database/encryption-key dependency for a deliberately small response cache. The default limit is **250 entries and 2 MiB of serialized JSON**, globally across users/environments. Older updated entries are evicted until both limits are met. It is a response cache, not a full offline ERP database or an unlimited historical archive. A larger future dataset should use another CacheService storage backend.

The existing package provides platform-specific secure persistence. Device storage and reboot behavior still require the release-device checks below. Web deployments require the secure context supported by flutter_secure_storage; browser site-data removal removes the cache.

Writes are serialized. Entries carry schema version, canonical key, endpoint, parameters, owner, creation/update timestamps, response and freshness duration. Damaged and incompatible entries are skipped safely; a wholly unreadable snapshot yields an empty cache and a storage warning. Schema changes deliberately discard incompatible entries rather than guess at migrations. Storage failures are surfaced through the app's nonblocking status strip and do not turn failed disk writes into false server failures.

## Keys and policy

Keys are canonical JSON arrays containing schema version, configured server URL, authenticated user, GET, endpoint and query parameters. Nested map keys are sorted recursively; array order is preserved. Document names are encoded by the existing Frappe wrapper. Fields, filters, ordering, supplier identifier, and pagination are part of the query and therefore part of the key. Distinct supplier advance requests and individual purchase documents cannot share a key. No headers or cookies are included.

Only reviewed GET resource DocTypes and the existing side-effect-free `app_advance` GET method are eligible. User document reads are excluded; the field-limited profile list query is eligible. Unknown methods, login/logout, and all POST/PUT/PATCH/DELETE operations bypass the response cache. There were no read-only POST methods in the existing application to allowlist. Adding one later requires an explicit policy and a key that includes its body; do not make POST caching automatic.

Successful read envelopes are validated as resource lists/documents or advance-method lists. Responses with Frappe exceptions, server messages or recursively detected authentication-secret fields are never persisted. Existing Frappe unwrapping and typed network errors remain in place.

| Data | Freshness |
| --- | --- |
| Purchase list | 5 minutes |
| Purchase document | 10 minutes |
| Supplier list, supplier options and references | 10 minutes |
| Supplier advances | 5 minutes |
| Field-limited User profile | 30 minutes |
| Roles and other reviewed references | 10 minutes |

Expiration controls revalidation, not offline deletion. Explicit screen loads/pull-to-refresh can revalidate a fresh entry too. `CacheManager.force` carries this refresh intent through repository calls using a Dart zone, so existing repository overrides and test doubles remain compatible. Background update consumers read without forcing another refresh.

## Loading, refresh and connectivity

- Cache hit: return the saved envelope immediately. If stale or explicitly refreshed and a network interface exists, start one shared request for the key.
- Cache miss: use the existing skeleton while fetching; validate and persist the successful response.
- Offline cache miss: return a friendly first-load error with Retry through the existing view-model error state.
- Failed background refresh: keep saved content. Display an offline or refresh-failed strip instead of replacing the screen.
- Changed response: persist, then emit the endpoint. App composition debounces these updates before requesting parsed data from the relevant view models. Reference-data updates refresh the existing purchase-form options. List and detail content remain mounted; existing SkeletonReveal transitions are retained.
- View models expose saved-data and refresh state. Detail refresh state uses the exact document path. Cached empty lists remain valid loaded states.

connectivity_plus interface changes are debounced for 600 ms. Dio connection/timeout failures mark the connection unavailable; HTTP responses such as 503 mark refresh failure without classifying the device as offline. The current session is revalidated before reconnect refreshes. Resume triggers another check. While foregrounded on a connected but unreachable network, a 30-second retry checks the authenticated server through the existing API; reconnect refresh cycles cannot overlap.

Connectivity API/lifecycle behavior follows the [package documentation](https://pub.dev/packages/connectivity_plus). Interface availability alone is never treated as confirmed server reachability.

## Mutations and invalidation

Offline mutations return an internet-required AppException before reaching Dio. If a network fails during a submission, the existing error UI reports failure; nothing is queued, replayed, marked complete or inserted as an unsent server record.

Confirmed resource mutations invalidate list variants and documents for that resource group. Purchase mutations also invalidate supplier-advance reads because allocations may have changed. Supplier creation invalidates supplier directory and supplier reference variants. User mutations invalidate User profile reads. Unrelated saved entries and unrelated active read requests remain intact. Revisions prevent a read started before invalidation from restoring obsolete data. Session generations prevent late responses from a previous account from populating the next account's state.

As with any non-idempotent online submission, a timeout can leave the server outcome unknown. There is deliberately no automatic mutation retry or replay.

## Authentication and security

Offline access requires an existing authenticated-session marker plus a saved identity for the exact server environment. The identity contains only server and user identifier; it does not contain credentials. A first-time offline user cannot sign in through cached API data.

Online restoration validates the real logged-in server user, activates that cache owner and reuses the identity result once to avoid duplicate startup identity requests. Network failure or a temporary server outage can retain the previously authenticated local identity; 401/403 responses are not accepted as an offline authentication fallback. Reconnect checks authorization before refreshing. A changed server identity expires the local session.

Logout/expiry clears the offline identity, the active user's saved responses, session marker and cookies. Supplier, profile, purchase list/detail, purchase references and advances are reset in memory. Late read or mutation completions cannot repopulate a different session. Server-confirmed denied/deleted cached records are evicted and removed from display; an optional restricted roles read can fall back to a profile without those roles.

Offline data reflects the last successfully authorized fetch. Server-side permission changes cannot be discovered while the device is disconnected; authorization is checked again when requests resume.

## Screen coverage

| Screen/data | Offline behavior |
| --- | --- |
| Dashboard | Existing static demo overview remains available; no API dashboard was present to cache. No invented live totals or endpoint were added. |
| Purchase list | Previously fetched list/filter/pagination variant is available. |
| Purchase details | Available for each previously opened document identifier. Loading a list does not automatically download every detail. |
| Supplier directory/information | Saved supplier records remain searchable. Tapping a supplier opens `/add-supplier/details/:supplierId`, which fetches and caches the full document per supplier ID. Previously opened details remain viewable offline, including custom fields and child records. |
| Purchase creation reference data | Previously fetched suppliers, items, warehouses, islands, companies, accounts, payment modes, UOMs, journals and supplier-specific advances remain available. Saving still requires internet. |
| Supplier creation | Existing static form choices remain usable; saving requires internet. |
| Profile | Previously fetched field-limited profile and accessible roles remain viewable; pull-to-refresh is available. |
| Settings and navigation | Existing local behavior and routes are preserved. |

Only fetched pages/documents remain available, subject to bounded-cache eviction. Nothing claims to download the full ERP database.

## Files created

- `lib/core/cache/cache_entry.dart`
- `lib/core/cache/cache_keys.dart`
- `lib/core/cache/cache_policy.dart`
- `lib/core/cache/cache_service.dart`
- `lib/core/cache/cache_manager.dart`
- `lib/core/network/connectivity_service.dart`
- `test/offline_cache_test.dart`
- `test/offline_api_integration_test.dart`
- `docs/offline-first.md`

## Existing files modified for this work

- `lib/app.dart`
- `lib/core/di/dependency_injection.dart`
- `lib/core/network/api_client.dart`
- `lib/core/network/frappe_resource_api.dart`
- `lib/features/auth/repositories/auth_repository.dart`
- `lib/features/auth/viewmodels/auth_viewmodel.dart`
- `lib/features/supplier/repositories/supplier_repository.dart`
- `lib/features/supplier/viewmodels/supplier_viewmodel.dart`
- `lib/features/supplier/views/add_supplier_screen.dart`
- `lib/features/point_of_purchase/repositories/point_of_purchase_repository.dart`
- `lib/features/point_of_purchase/viewmodels/point_of_purchase_viewmodel.dart`
- `lib/features/point_of_purchase/views/point_of_purchase_screen.dart`
- `lib/features/point_of_purchase/views/point_of_purchase_detail_screen.dart`
- `lib/features/point_of_purchase/views/create_point_of_purchase_screen.dart`
- `lib/features/profile/repositories/profile_repository.dart`
- `lib/features/profile/viewmodels/profile_viewmodel.dart`
- `lib/features/profile/views/profile_screen.dart`
- `pubspec.yaml`, `pubspec.lock`
- Generated connectivity registration in `macos/Flutter/GeneratedPluginRegistrant.swift`, `windows/flutter/generated_plugin_registrant.cc`, `windows/flutter/generated_plugins.cmake`

## Validation and device acceptance procedure

Verified results:

- `flutter test`: **99 tests passed**, including 28 cache/API integration cases and 3 supplier-details tests.
- `flutter analyze`: no new errors or lints; one existing unused `_erpFieldsSection` warning remains in the purchase form. The analyzer exits nonzero because of that existing warning.
- `git diff --check`: passed.
- Release APK compilation succeeded. Builds here omit the real server URL and establish compilation only, not live-backend or device acceptance.
- Latest regression output is in `build/supplier-details-test-results.log` (the earlier offline suite is in `build/offline-test-results.log`); release build output is in `build/offline-release-build.log` (ignored build artifacts).

Automated tests cover canonical keys, freshness boundaries, restart persistence, no-cache offline errors, stale-while-revalidate, failed refresh fallback, concurrent cold reads and refreshes, selective invalidation, superseded requests, size/entry limits, damaged/versioned entries, environment/account isolation, offline mutation guards, real Dio timeout vs HTTP-error classification, offline session restoration, online account correction, denied cached reads, and detail content retention.

Run:

```powershell
flutter analyze
flutter test
flutter build apk --release --dart-define=FRAPPE_BASE_URL=https://your-server
```

The existing analyzer warning about the unused `_erpFieldsSection` in the purchase form predates this change and is retained rather than deleting unrelated form code. Release compilation is a build check, not a substitute for a real device test. A build without `FRAPPE_BASE_URL` is useful for compilation but cannot authenticate against a server in release mode.

On a signed release APK configured with the real server:

1. Start online, sign in, visit purchase list, open several purchase details, visit suppliers, open purchase references/advances for two different suppliers, and visit profile. Confirm server data and the existing skeletons on first loads.
2. Force-stop the application, enable airplane mode and relaunch. Confirm the local session restores and each visited screen shows its saved data. Open two different details and supplier advance selections to verify identity-specific keys. Reboot and repeat.
3. Open an unvisited document or clear application data and launch offline. Confirm a friendly empty/error state with Retry; do not expect unvisited records to be available.
4. Reconnect. Change a record on the server, then pull-to-refresh. Confirm old content remains during the request, fresh data arrives, and scroll position is retained. Repeat with a timeout, DNS failure, Wi-Fi without internet, and HTTP 503. HTTP 503 must show refresh failure rather than offline classification.
5. Attempt supplier/purchase submission offline. Confirm an internet-required message and no success/navigation or queued transaction.
6. Create/update a record online. Confirm related lists/references reload and unrelated cached screens remain available.
7. Log out offline. Relaunch and confirm sign-in is required. Log in as another account and verify no prior user's records appear. Repeat with a different configured server and with an expired server session.
8. Verify Android/device secure-storage behavior after process termination and reboot. No Android device was connected in the implementation environment, so these hardware/network steps require manual acceptance.

## Supplier details extension

`lib/features/supplier/views/supplier_details_screen.dart` adds supplier-specific full-document viewing from a tapped directory card. The existing Supplier repository/view model now manage detail requests separately from the list, prevent older requests from replacing a newly selected supplier, reset details on logout, preserve content on refresh failure, and consume background cache updates/reconnect refreshes. Routes are defined in the existing GoRouter configuration.

The screen includes grouped supplier, contact/address, and tax/payment information, plus additional custom fields and expandable child records. Empty values display a placeholder; secret/internal fields are excluded. Pull-to-refresh, loading skeletons and Retry use the existing app components. Full detail data requires an initial successful document fetch; a list fetch alone does not download every supplier document.

`test/supplier_details_test.dart` checks tap navigation (including supplier IDs containing a slash and spaces), custom fields/child rows, returning to the list, retry/deduplication, content retention, superseded requests, and session reset.
