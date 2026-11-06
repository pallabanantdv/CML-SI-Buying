import '../../../core/diagnostics/diagnostic_notifier.dart';
import '../../../core/errors/app_exception.dart';
import '../repositories/supplier_payment_repository.dart';

class SupplierPaymentViewModel extends DiagnosticNotifier {
  SupplierPaymentViewModel(this.repository);
  final SupplierPaymentRepository repository;
  List<Map<String, dynamic>> companies = [],
      suppliers = [],
      modes = [],
      accounts = [],
      invoices = [];
  String? company, supplier, mode, paidFrom, paidTo, invoice;
  bool loading = false,
      loadingAccounts = false,
      loadingInvoices = false,
      saving = false;
  String? error, accountError, invoiceError;
  int _accountRequest = 0, _invoiceRequest = 0;

  Map<String, dynamic>? find(List<Map<String, dynamic>> rows, String? name) =>
      rows.where((row) => row['name'] == name).firstOrNull;
  String get companyCurrency =>
      '${find(companies, company)?['default_currency'] ?? ''}';
  String get fromCurrency =>
      '${find(accounts, paidFrom)?['account_currency'] ?? companyCurrency}';
  String get toCurrency =>
      '${find(accounts, paidTo)?['account_currency'] ?? companyCurrency}';
  bool get bankPayment => find(accounts, paidFrom)?['account_type'] == 'Bank';
  List<Map<String, dynamic>> get sourceAccounts => accounts
      .where((row) => ['Bank', 'Cash'].contains(row['account_type']))
      .toList();
  List<Map<String, dynamic>> get partyAccounts => accounts
      .where((row) => ['Payable', 'Receivable'].contains(row['account_type']))
      .toList();
  String _message(Object e) => e is AppException
      ? e.message
      : 'Unable to load payment options. Please retry.';

  Future<void> initialize() async {
    if (loading || isDisposed) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final rows = await Future.wait([
        repository.companies(),
        repository.suppliers(),
        repository.modes(),
      ]);
      if (isDisposed) return;
      companies = rows[0];
      suppliers = rows[1];
      modes = rows[2];
    } catch (e) {
      if (!isDisposed) error = _message(e);
    } finally {
      if (!isDisposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectCompany(String? value) async {
    final request = ++_accountRequest;
    ++_invoiceRequest;
    company = value;
    paidFrom = null;
    paidTo = null;
    invoice = null;
    accounts = [];
    invoices = [];
    accountError = null;
    invoiceError = null;
    loadingAccounts = value != null;
    loadingInvoices = false;
    notifyListeners();
    if (value == null) return;
    try {
      final rows = await repository.accounts(value);
      if (isDisposed || request != _accountRequest) return;
      accounts = rows;
    } catch (e) {
      if (!isDisposed && request == _accountRequest) accountError = _message(e);
    } finally {
      if (!isDisposed && request == _accountRequest) {
        loadingAccounts = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadInvoices() async {
    final request = ++_invoiceRequest;
    invoice = null;
    invoices = [];
    invoiceError = null;
    loadingInvoices = company != null && supplier != null && paidTo != null;
    notifyListeners();
    if (!loadingInvoices) return;
    try {
      final rows = await repository.invoices(company!, supplier!, toCurrency);
      if (isDisposed || request != _invoiceRequest) return;
      invoices = rows.where((row) => row['credit_to'] == paidTo).toList();
    } catch (e) {
      if (!isDisposed && request == _invoiceRequest) invoiceError = _message(e);
    } finally {
      if (!isDisposed && request == _invoiceRequest) {
        loadingInvoices = false;
        notifyListeners();
      }
    }
  }

  Future<String?> save({
    required String date,
    required double amount,
    required double received,
    required double sourceRate,
    required double targetRate,
    required String reference,
    required String referenceDate,
    required String remarks,
    required double allocated,
  }) async {
    if (saving || loading || loadingAccounts || isDisposed) return null;
    error = null;
    if (company == null ||
        supplier == null ||
        mode == null ||
        paidFrom == null ||
        paidTo == null ||
        find(companies, company) == null ||
        find(suppliers, supplier) == null ||
        find(modes, mode) == null ||
        !sourceAccounts.any((row) => row['name'] == paidFrom) ||
        !partyAccounts.any((row) => row['name'] == paidTo)) {
      error = 'Select the company, supplier, payment mode and both accounts.';
    } else if (paidFrom == paidTo ||
        [
          amount,
          received,
          sourceRate,
          targetRate,
        ].any((value) => !value.isFinite || value <= 0) ||
        !(amount * sourceRate).isFinite ||
        !(received * targetRate).isFinite) {
      error = 'Enter valid positive amounts and exchange rates.';
    } else if (fromCurrency.isEmpty ||
        toCurrency.isEmpty ||
        companyCurrency.isEmpty) {
      error = 'The selected company or accounts have no currency configured.';
    } else if ((fromCurrency == companyCurrency && sourceRate != 1) ||
        (toCurrency == companyCurrency && targetRate != 1)) {
      error = 'Exchange rates for company-currency accounts must be 1.';
    } else if ((amount * sourceRate - received * targetRate).abs() > 0.005) {
      error = 'Paid and received amounts must balance in company currency.';
    } else if (bankPayment &&
        (reference.trim().isEmpty || referenceDate.isEmpty)) {
      error = 'Enter the bank reference number and reference date.';
    } else if (invoice != null &&
        (find(invoices, invoice) == null ||
            !allocated.isFinite ||
            allocated <= 0 ||
            allocated > received ||
            allocated >
                (num.tryParse(
                      '${find(invoices, invoice)?['outstanding_amount']}',
                    ) ??
                    0))) {
      error = 'Allocated amount must not exceed the invoice outstanding or received amount.';
    }
    if (error != null) {
      notifyListeners();
      return null;
    }
    saving = true;
    notifyListeners();
    try {
      return await repository.create({
        'payment_type': 'Pay',
        'party_type': 'Supplier',
        'party': supplier,
        'company': company,
        'posting_date': date,
        'mode_of_payment': mode,
        'paid_from': paidFrom,
        'paid_to': paidTo,
        'paid_from_account_currency': fromCurrency,
        'paid_to_account_currency': toCurrency,
        'paid_amount': amount,
        'received_amount': received,
        'source_exchange_rate': sourceRate,
        'target_exchange_rate': targetRate,
        'base_paid_amount': amount * sourceRate,
        'base_received_amount': received * targetRate,
        if (reference.trim().isNotEmpty) 'reference_no': reference.trim(),
        if (referenceDate.isNotEmpty) 'reference_date': referenceDate,
        if (remarks.trim().isNotEmpty) ...{
          'custom_remarks': 1,
          'remarks': remarks.trim(),
        },
        'references': [
          if (invoice != null)
            {
              'reference_doctype': 'Purchase Invoice',
              'reference_name': invoice,
              'total_amount': find(invoices, invoice)?['grand_total'],
              'outstanding_amount': find(
                invoices,
                invoice,
              )?['outstanding_amount'],
              'allocated_amount': allocated,
            },
        ],
        'docstatus': 0,
      });
    } catch (e) {
      if (!isDisposed) {
        error = e is AppException
            ? e.message
            : 'Unable to save payment entry. Please retry.';
      }
      return null;
    } finally {
      if (!isDisposed) {
        saving = false;
        notifyListeners();
      }
    }
  }
}
