import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/app_dimensions.dart';
import '../../../shared/widgets/app_app_bar.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_error_widget.dart';
import '../../../shared/widgets/app_form_action_bar.dart';
import '../../../shared/widgets/app_header_title.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/skeleton/skeleton.dart';
import '../viewmodels/supplier_payment_viewmodel.dart';

class CreatePaymentEntryScreen extends StatefulWidget {
  const CreatePaymentEntryScreen({super.key});
  @override
  State<CreatePaymentEntryScreen> createState() =>
      _CreatePaymentEntryScreenState();
}

class _CreatePaymentEntryScreenState extends State<CreatePaymentEntryScreen> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _remarks = TextEditingController();
  final _allocated = TextEditingController();
  DateTime _date = DateTime.now();
  DateTime? _referenceDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(context.read<SupplierPaymentViewModel>().initialize());
      }
    });
  }

  @override
  void dispose() {
    for (final controller in [_amount, _reference, _remarks, _allocated]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _stamp(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  double _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? double.nan;
  String? _positive(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    return number == null || !number.isFinite || number <= 0
        ? 'Enter a positive number.'
        : null;
  }

  void _resetAmounts(SupplierPaymentViewModel vm) {
    _allocated.clear();
  }

  Widget _select(
    String label,
    String? value,
    List<Map<String, dynamic>> rows,
    ValueChanged<String?> onChanged, {
    String? titleField,
  }) {
    final vm = context.read<SupplierPaymentViewModel>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppDropdown<String>(
        label: '$label *',
        value: value,
        enabled: !vm.saving && !vm.loadingAccounts,
        hint: 'Select ${label.toLowerCase()}',
        onSearch: titleField == 'supplier_name'
            ? (query) async {
                final results = await vm.searchSuppliers(query);
                return [
                  for (final row in results)
                    DropdownMenuItem<String>(
                      value: '${row['name']}',
                      child: Text(
                        '${row['supplier_name'] ?? row['name']} (${row['name']})',
                      ),
                    ),
                ];
              }
            : null,
        validator: (value) =>
            value == null ? 'Select ${label.toLowerCase()}.' : null,
        items: [
          for (final row in rows)
            DropdownMenuItem(
              value: '${row['name']}',
              child: Text(
                titleField == null
                    ? '${row['name']}'
                    : '${row[titleField] ?? row['name']} (${row['name']})',
              ),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _numberField(
    String label,
    TextEditingController controller, {
    ValueChanged<String>? onChanged,
    bool enabled = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: AppTextField(
      controller: controller,
      label: label,
      required: true,
      enabled: enabled && !context.read<SupplierPaymentViewModel>().saving,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: _positive,
      onChanged: onChanged,
    ),
  );

  Widget _dateField(
    String label,
    DateTime? value,
    ValueChanged<DateTime> changed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: OutlinedButton.icon(
      onPressed: context.read<SupplierPaymentViewModel>().saving
          ? null
          : () async {
              final result = await showDatePicker(
                context: context,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (mounted && result != null) setState(() => changed(result));
            },
      icon: const Icon(Icons.calendar_today_outlined),
      label: Text('$label: ${value == null ? 'Select date' : _stamp(value)}'),
    ),
  );

  Future<void> _save() async {
    final vm = context.read<SupplierPaymentViewModel>();
    if (vm.saving) return;
    FocusScope.of(context).unfocus();
    if (!await validateAndReveal(_form) || !mounted) return;
    final name = await vm.save(
      date: _stamp(_date),
      amount: _number(_amount),
      received: _number(_amount),
      sourceRate: 1,
      targetRate: 1,
      reference: _reference.text,
      referenceDate: _referenceDate == null ? '' : _stamp(_referenceDate!),
      remarks: _remarks.text,
      allocated: vm.invoice == null ? 0 : _number(_allocated),
    );
    if (!mounted) return;
    if (name != null) {
      context.pop(name);
    } else {
      AppSnackbar.show(
        context,
        vm.error ?? 'Unable to save payment entry.',
        type: AppMessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Consumer<SupplierPaymentViewModel>(
    builder: (context, vm, _) => Scaffold(
      appBar: const AppAppBar(
        title: AppHeaderTitle(title: 'Supplier payment entry'),
      ),
      bottomNavigationBar: AppFormActionBar(
        label: 'Save draft',
        isLoading: vm.saving,
        onPressed:
            vm.loading ||
                vm.loadingAccounts ||
                vm.saving ||
                vm.companies.isEmpty
            ? null
            : _save,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.formMaxWidth,
            ),
            child: vm.loading
                ? const SkeletonShimmer(
                    label: 'Loading payment options...',
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: SkeletonInfoRows(count: 8),
                    ),
                  )
                : vm.companies.isEmpty
                ? AppErrorWidget(
                    message: vm.error ?? 'No companies are available for payment entry. Check your ERPNext permissions and retry.',
                    onRetry: () => unawaited(vm.initialize()),
                  )
                : Form(
                    key: _form,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // const Text(
                        //   'Record a supplier payment or advance. Saving creates a draft for review in ERPNext.',
                        // ),
                        AppCard(
                          title: 'Payment details',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),
                              _dateField(
                                'Posting date',
                                _date,
                                (value) => _date = value,
                              ),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Supplier Advance Transfer'),
                                value: vm.supplierAdvanceTransfer,
                                onChanged: vm.saving
                                    ? null
                                    : (value) {
                                        vm.setSupplierAdvanceTransfer(
                                          value ?? false,
                                        );
                                        _resetAmounts(vm);
                                      },
                              ),
                              AppDropdown<String>(
                                label: 'Payment Type',
                                value: vm.paymentType,
                                enabled: !vm.saving,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Pay',
                                    child: Text('Pay'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Receive',
                                    child: Text('Receive'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  vm.setSupplierAdvanceTransfer(
                                    value == 'Receive',
                                  );
                                  _resetAmounts(vm);
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text('Party Type: Supplier'),
                              const SizedBox(height: 16),

                              if (vm.supplierAdvanceTransfer) ...[
                                _select(
                                  'Supplier',
                                  vm.transferSupplier,
                                  vm.suppliers,
                                  (value) => setState(
                                    () => vm.transferSupplier = value,
                                  ),
                                  titleField: 'supplier_name',
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    'The advance will be deducted from this supplier and added to the Party selected below.',
                                  ),
                                ),
                              ],
                              _select('Party', vm.supplier, vm.suppliers, (
                                value,
                              ) {
                                vm.supplier = value;
                                _allocated.clear();
                                unawaited(vm.loadInvoices());
                              }, titleField: 'supplier_name'),
                              if (vm.supplier != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    'Party Name: ${vm.find(vm.suppliers, vm.supplier)?['supplier_name'] ?? vm.supplier}',
                                  ),
                                ),
                              _select('Mode of Payment', vm.mode, vm.modes, (
                                value,
                              ) {
                                vm.mode = value;
                                vm.selectDefaultAccounts();
                                _allocated.clear();
                                unawaited(vm.loadInvoices());
                              }),

                              _numberField(
                                'Paid amount (${vm.fromCurrency})',
                                _amount,
                              ),
                            ],
                          ),
                        ),
                        // const SizedBox(height: 16),
                        // AppCard(
                        //   title: 'Accounts and amounts',
                        //   child: Column(
                        //     crossAxisAlignment: CrossAxisAlignment.stretch,
                        //     children: [
                        //       if (vm.loadingAccounts)
                        //         const LinearProgressIndicator(),
                        //       if (vm.accountError != null) ...[
                        //         Text(vm.accountError!),
                        //         TextButton(
                        //           onPressed: () =>
                        //               unawaited(vm.selectCompany(vm.company)),
                        //           child: const Text('Retry accounts'),
                        //         ),
                        //       ],

                        //     ],
                        //   ),
                        // ),

                        // const SizedBox(height: 16),
                        // if (!vm.supplierAdvanceTransfer)
                        //   AppCard(
                        //     title: 'Invoice allocation (optional)',
                        //     child: Column(
                        //       crossAxisAlignment: CrossAxisAlignment.stretch,
                        //       children: [
                        //         const Text(
                        //           'Leave as advance to make a payment without an invoice reference.',
                        //         ),
                        //         if (vm.loadingInvoices)
                        //           const LinearProgressIndicator(),
                        //         if (vm.invoiceError != null) ...[
                        //           Text(vm.invoiceError!),
                        //           TextButton(
                        //             onPressed: () =>
                        //                 unawaited(vm.loadInvoices()),
                        //             child: const Text('Retry invoices'),
                        //           ),
                        //         ],
                        //         const SizedBox(height: 12),
                        //         AppDropdown<String>(
                        //           label: 'Purchase Invoice',
                        //           value: vm.invoice ?? '__advance__',
                        //           enabled: !vm.saving && !vm.loadingInvoices,
                        //           items: [
                        //             const DropdownMenuItem(
                        //               value: '__advance__',
                        //               child: Text('Pay as advance'),
                        //             ),
                        //             for (final row in vm.invoices)
                        //               DropdownMenuItem(
                        //                 value: '${row['name']}',
                        //                 child: Text(
                        //                   '${row['name']} · Outstanding ${row['outstanding_amount']} ${vm.toCurrency}',
                        //                 ),
                        //               ),
                        //           ],
                        //           onChanged: (value) => setState(() {
                        //             vm.invoice = value == '__advance__'
                        //                 ? null
                        //                 : value;
                        //             _allocated.text = vm.invoice == null
                        //                 ? ''
                        //                 : '${vm.find(vm.invoices, vm.invoice)?['outstanding_amount'] ?? ''}';
                        //           }),
                        //         ),
                        //         if (vm.invoice != null) ...[
                        //           const SizedBox(height: 16),
                        //           _numberField(
                        //             'Allocated amount (${vm.toCurrency})',
                        //             _allocated,
                        //           ),
                        //         ],
                        //       ],
                        //     ),
                        //   ),
                        const SizedBox(height: 16),
                        AppCard(
                          title: 'Transaction reference',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              AppTextField(
                                controller: _reference,
                                label: 'Reference / cheque number',
                                required: vm.bankPayment,
                                enabled: !vm.saving,
                                validator: (value) =>
                                    vm.bankPayment &&
                                        (value?.trim().isEmpty ?? true)
                                    ? 'Enter the bank reference number.'
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              _dateField(
                                vm.bankPayment
                                    ? 'Reference date *'
                                    : 'Reference date',
                                _referenceDate,
                                (value) => _referenceDate = value,
                              ),
                              AppTextField(
                                controller: _remarks,
                                label: 'Remarks',
                                enabled: !vm.saving,
                              ),
                            ],
                          ),
                        ),
                        if (vm.error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            vm.error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    ),
  );
}
