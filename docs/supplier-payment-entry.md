# Supplier Payment Entry

Open **Suppliers → Payment Entry** to record a supplier payment or advance.
The form saves a real **draft** Payment Entry through the existing authenticated
resource API. It does not submit the document or post ledger entries. Review and
submit it from **View payment entries** or in ERPNext. The confirmation displays
the saved entry number.

## List and submission

**Suppliers → View payment entries** opens a paginated list of supplier payments,
with All, Draft, Submitted and Cancelled filters. Pull to refresh, or use Load
more for older records. New payment entry opens the existing creation form and
refreshes the list after a successful draft save.

Only drafts have a Submit action. Submission re-reads the complete document from
the server using `frappe.client.get`, checks that it is still a draft supplier
payment, and passes it to `frappe.client.submit`. This runs ERPNext's submission
permissions, validations and accounting lifecycle. It does not update docstatus
directly. The UI switches to Submitted only after a response with the same name
and `docstatus=1`. In the Draft filter the submitted record disappears. Failed
submissions retain the draft and expose the server error, with refresh available.
Repeated submissions and refresh races are blocked while a submission is pending.
Successful submission invalidates cached supplier advance reads.

The form includes company, posting date, supplier, payment mode, source bank/cash
account, supplier payable/advance account, paid and received amounts, source and
target exchange rates, transaction reference, reference date and remarks.
`payment_type` is `Pay`; `party_type` is `Supplier`.

Companies, enabled suppliers, modes, company-specific ledger accounts and
outstanding Purchase Invoices come from ERPNext. Changing company clears the
selected accounts and invoice. Invoice choices also match the selected supplier,
account and currency. Outdated async responses cannot replace a newer selection.

An optional single Purchase Invoice can be allocated partially or fully. Leaving
the selection at **Pay as advance** sends an empty references array. Allocation
cannot exceed either the received amount or the invoice outstanding amount. A
payment may leave a remainder as an unallocated advance. Multiple-invoice
allocations and deduction/write-off rows are outside this form's current scope.

Amounts and rates must be finite and positive. Company-currency accounts use an
exchange rate of 1. Paid and received amounts must balance in company currency;
the form does not invent exchange gain/loss deductions. Bank payments require
a reference number and reference date. ERPNext remains authoritative for account
permissions, company-specific advance settings, current outstanding amounts,
custom mandatory fields and all server validation. Server errors keep the form
and entered values available for correction.

Document numbering uses ERPNext's configured default naming series. No series,
account, company or supplier identifiers are hardcoded.

Implementation: `SupplierPaymentRepository`, `SupplierPaymentViewModel`,
`CreatePaymentEntryScreen`, and the `create-payment-entry` GoRouter route. The
route owns the payment ViewModel and reuses the existing SupplierRepository's
authenticated resource API. No independent Dio client or credentials are added.

Validation tests cover draft payloads, bank references, invalid amounts, balanced
amounts, invoice limits, duplicate saves, company resets, the Payment Entry REST
contract, and form validation. Tests use fake transports; no live financial
documents are created during validation.

ERP field reference: [Payment Entry](https://docs.frappe.io/erpnext/payment-entry).
