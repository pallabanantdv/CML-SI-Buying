# Submitting a draft Point of Purchase

The purchase details screen shows **Save** and **Update** in the header only for a loaded record with `docstatus = 0`. The Save action submits the draft. It is disabled while a detail refresh or submission is in progress. Submitted (`1`) and cancelled (`2`) records have no Submit action.

The view calls the existing PointOfPurchaseViewModel and repository. The repository reads the latest document through the uncached `frappe.client.get` method, checks that it is still a draft, then POSTs the complete document to `frappe.client.submit`. This uses Frappe's actual document submission lifecycle rather than directly changing the status field. The endpoint contract is documented in the [Frappe client source](https://github.com/frappe/frappe/blob/develop/frappe/client.py).

Only a response for the requested document with `docstatus = 1` is accepted as confirmed submission. On success, the view model updates the details and list record, refreshes the list, and resets old supplier advance balances. The repository invalidates affected purchase/advance read caches and persists the server-confirmed document under its usual GET cache key. Account-generation and request guards prevent earlier reads or another session from publishing an obsolete result.

Offline attempts fail with an internet-required message. Validation/permission failures retain the draft and display the server error. No mutation is cached, queued, or automatically retried. If a timeout leaves the result uncertain, refresh the document before trying again; its current server status is checked on every attempt.

`test/purchase_submission_test.dart` verifies the button lifecycle, draft-only guards, repeated taps, session isolation, full-document POST payload (including child rows), confirmed cache updates, offline blocking, server validation errors, and unconfirmed responses. Tests use a simulated backend; submitting a live ERP document was not performed during development.

## Editing an existing draft

**Update** opens `CreatePointOfPurchaseScreen` in edit mode for the selected document. The route carries its identifier in `documentName`, so the editor can also load the document when opened directly. The loaded snapshot prefills text, links, date/time, bags, cash payments, and advance allocations. The original Company remains selected instead of being replaced by the first Company option. Reset restores that loaded snapshot.

**Save in the editor** updates the existing draft using PUT on its resource endpoint. It does not create or submit a document. The backend's latest draft status and `modified` timestamp are checked first; conflicting server changes require reopening the record. Child-row identifiers/custom fields, additional existing items and unchanged advance allocations are retained. Explicitly cleared optional values are sent as clears. Read-only paid/GST fields and the document name/status are not overwritten by form defaults. After confirmed success, the editor returns to the detail page and refreshes its data and related caches.

`test/purchase_edit_test.dart` covers navigation/prefill, Company preservation, date/time, retaining child data, correct PUT identity, explicit clears, failed-save retention, Reset, stale/submitted document guards, and narrow-phone header actions with large text.

## Purchase form calculations

Advance Table rows are sent in the `advance` array on creation and update. Unchanged allocations retain their original child-row fields when editing.

The form displays and sends these live calculations:

- `ship_payment` = Freight Amount + Others + Sea Fare.
- `total_amount` = summed bag weight in kg ? Rate/kg.
- `grand_total` = Total Amount.
- `total_deduction` = Ship Payment, excluding advances.
- `net_payable` = Grand Total ? Total Deduction ? Advances Deduction.
- `tare15kgsbag` = the sum of every bag row's tare, shown as the read-only Tare per bag (kg) field.

Totals update when inputs or bag rows change and reset with the form. Net payable follows the subtraction formula directly, including negative results; it is not silently clamped to zero. Existing additional item rows remain preserved when editing, while the document totals follow the bag-weight ? Rate/kg formula above.

`test/purchase_totals_test.dart` checks live totals, multiple bag tares, bag removal, changed rates/advances, and Reset. Create/update payload regression tests also assert the computed totals and `advance` rows.
