import 'package:flutter_test/flutter_test.dart';
import 'package:cml_si_buying/features/supplier/viewmodels/supplier_payment_viewmodel.dart';

import 'supplier_payment_test.dart' as fixtures;

class _CamlPayments extends fixtures.Payments {
  bool includeCash = true;
  String cashCurrency = 'SBD';

  @override
  Future<List<Map<String, dynamic>>> companies() async => [
    {'name': 'Other company', 'default_currency': 'USD'},
    {'name': SupplierPaymentViewModel.camlCompany, 'default_currency': 'SBD'},
  ];

  @override
  Future<List<Map<String, dynamic>>> accounts(String company) async => [
    // Deliberately put other accounts first to catch API-order dependence.
    {'name': 'Other cash', 'account_type': 'Cash', 'account_currency': 'SBD'},
    {
      'name': 'Other payable',
      'account_type': 'Payable',
      'account_currency': 'SBD',
    },
    if (includeCash)
      {
        'name': SupplierPaymentViewModel.camlCashAccount,
        'account_type': 'Cash',
        'account_currency': cashCurrency,
      },
    {
      'name': SupplierPaymentViewModel.camlAdvanceAccount,
      'account_type': 'Payable',
      'account_currency': 'SBD',
    },
  ];
}

void main() {
  test(
    'CAML cash draft uses the requested ledgers regardless of API order',
    () async {
      final repository = _CamlPayments();
      final vm = SupplierPaymentViewModel(repository);
      addTearDown(vm.dispose);
      await vm.initialize();
      vm.supplier = 'SUP-1';
      expect(vm.company, SupplierPaymentViewModel.camlCompany);
      expect(vm.mode, 'Cash');
      expect(vm.paidFrom, SupplierPaymentViewModel.camlCashAccount);
      expect(vm.paidTo, SupplierPaymentViewModel.camlAdvanceAccount);
      expect(await fixtures.save(vm), isNotNull);
      expect(
        repository.payload,
        containsPair('paid_from', SupplierPaymentViewModel.camlCashAccount),
      );
      expect(
        repository.payload,
        containsPair('paid_to', SupplierPaymentViewModel.camlAdvanceAccount),
      );
      expect(
        repository.payload,
        containsPair('naming_series', 'CAML-PAY-.YYYY.-'),
      );
      expect(repository.payload, containsPair('doctype', 'Payment Entry'));
      expect(repository.payload, containsPair('party_name', 'Supplier A'));
      expect(
        repository.payload,
        containsPair('book_advance_payments_in_separate_party_account', 1),
      );
      expect(
        repository.payload,
        containsPair('paid_from_account_type', 'Cash'),
      );
      expect(
        repository.payload,
        containsPair('paid_to_account_type', 'Payable'),
      );
      expect(repository.payload, containsPair('paid_amount', 100));
      expect(repository.payload, containsPair('received_amount', 100));
      expect(repository.payload, containsPair('docstatus', 0));
      expect(repository.payload!['references'], isEmpty);
      for (final field in [
        'owner',
        'creation',
        'modified',
        'name',
        'localname',
        '__onload',
        'party_balance',
        'paid_from_account_balance',
      ]) {
        expect(repository.payload, isNot(contains(field)));
      }
    },
  );

  test('missing or foreign-currency CAML cash default cannot use another cash ledger silently', () async {
    for (final missing in [true, false]) {
      final repository = _CamlPayments()
        ..includeCash = !missing
        ..cashCurrency = missing ? 'SBD' : 'USD';
      final vm = SupplierPaymentViewModel(repository);
      await vm.initialize();
      vm.supplier = 'SUP-1';
      expect(vm.paidFrom, isNull);
      expect(vm.accountError, isNotNull);
      expect(await fixtures.save(vm), isNull);
      expect(repository.payload, isNull);
      vm.dispose();
    }
  });

  test('advance transfer preserves the selected CAML accounts in reverse direction', () async {
    final repository = _CamlPayments();
    final vm = SupplierPaymentViewModel(repository);
    addTearDown(vm.dispose);
    await vm.initialize();
    vm.supplier = 'SUP-1';
    vm.setSupplierAdvanceTransfer(true);
    vm.transferSupplier = 'SUP-2';
    expect(await fixtures.save(vm), isNotNull);
    expect(repository.payload, containsPair('payment_type', 'Receive'));
    expect(
      repository.payload,
      containsPair('paid_from', SupplierPaymentViewModel.camlAdvanceAccount),
    );
    expect(
      repository.payload,
      containsPair('paid_to', SupplierPaymentViewModel.camlCashAccount),
    );
    expect(repository.payload, containsPair('custom_supplier', 'SUP-2'));
  });
}
