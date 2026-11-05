import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/app_dimensions.dart';
import '../../../core/utils/number_format.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../shared/widgets/app_app_bar.dart';
import '../../../shared/widgets/app_form_action_bar.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_checkbox.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_header_title.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/skeleton/skeleton.dart';
import '../viewmodels/point_of_purchase_viewmodel.dart';
import '../models/calculated_purchase_item.dart';

class CreatePointOfPurchaseScreen extends StatefulWidget {
  const CreatePointOfPurchaseScreen({super.key});

  @override
  State<CreatePointOfPurchaseScreen> createState() =>
      _CreatePointOfPurchaseScreenState();
}

class _CreatePointOfPurchaseScreenState
    extends State<CreatePointOfPurchaseScreen> {
  var _formKey = GlobalKey<FormState>();
  var _purchaseItemKey = GlobalKey<FormFieldState<bool>>();
  final List<_BagDraft> _bags = [_BagDraft(1)];
  final List<_CashPaymentDraft> _cashPayments = [];
  final Map<String, TextEditingController> _fields = {};
  final Map<String, String?> _links = {};
  String? _supplier;
  String? _deliveryType;
  String? _productType;
  DateTime _purchaseDate = DateTime.now();
  TimeOfDay _purchaseTime = TimeOfDay.now();
  bool _instantPaid = false;
  bool _optionsRequested = false;

  bool _optionsLoading(PointOfPurchaseViewModel viewModel) =>
      !_optionsRequested ||
      (viewModel.isLoadingCreateOptions && !viewModel.hasCreateOptions);
  int _nextBagNumber = 2;

  @override
  void initState() {
    super.initState();
    // Start provider updates after the first frame. Notifying listeners from
    // initState can make the screen's Consumer rebuild while Flutter is still
    // building the route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final viewModel = context.read<PointOfPurchaseViewModel>();
      _optionsRequested = true;
      viewModel.clearCreateError();
      viewModel.clearSupplierAdvances();
      unawaited(viewModel.loadCreateOptions());
    });
  }

  @override
  void dispose() {
    for (final row in _bags) {
      row.dispose();
    }
    for (final row in _cashPayments) {
      row.dispose();
    }
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Consumer<PointOfPurchaseViewModel>(
    builder: (context, viewModel, _) => Scaffold(
      appBar: const AppAppBar(title: AppHeaderTitle(title: 'New purchase')),
      bottomNavigationBar: AppFormActionBar(
        label: 'Save purchase',
        isLoading: viewModel.isCreating,
        onPressed: viewModel.isCreating ? null : () => _submit(viewModel),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppDimensions.detailContentMaxWidth,
            ),
            child: SkeletonShimmer(
              enabled: _optionsLoading(viewModel),
              placeholdersOnly: false,
              label: 'Loading purchase form options...',
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.all(AppDimensions.pageGutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (viewModel.createOptionsError != null) ...[
                        _MessagePanel(
                          message: viewModel.createOptionsError!,
                          isError: true,
                          action: TextButton(
                            onPressed: () =>
                                unawaited(viewModel.loadCreateOptions()),
                            child: const Text('Retry'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sectionGap),
                      ],
                      _supplierSection(viewModel),
                      const SizedBox(height: AppSpacing.sectionGap),
                      _deliverySection(viewModel),
                      const SizedBox(height: AppSpacing.sectionGap),
                      _buildBagTable(),
                      const SizedBox(height: AppSpacing.sectionGap),
                      _pricingSection(viewModel),

                      if (_fieldText('advances').isNotEmpty &&
                          viewModel.validateAdvanceDeduction(
                                _fieldText('advances'),
                              ) ==
                              null &&
                          _number(_fieldText('advances')) > 0) ...[
                        const SizedBox(height: AppSpacing.sectionGap),
                        _buildAdvanceTable(viewModel),
                      ],
                      const SizedBox(height: AppSpacing.sectionGap),
                      _buildItemTable(viewModel),
                      const SizedBox(height: AppSpacing.sectionGap),
                      // const AppCard(
                      //   tone: AppCardTone.info,
                      //   showAccentBar: false,
                      //   title: 'Invoice advances',
                      //   leading: AppSvgIcon(icon: AppIconName.inventory),
                      //   child: Text(
                      //     'This read-only table is filled automatically by the ERP when an invoice advance applies.',
                      //   ),
                      // ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      _paymentAndAccountsSection(viewModel),
                      const SizedBox(height: AppSpacing.sectionGap),
                      // _erpFieldsSection(viewModel),
                      if (_instantPaid) ...[
                        const SizedBox(height: AppSpacing.sectionGap),
                        _buildCashPaymentTable(viewModel),
                      ],
                      if (viewModel.createErrorMessage != null) ...[
                        const SizedBox(height: AppSpacing.sectionGap),
                        _MessagePanel(
                          message: viewModel.createErrorMessage!,
                          isError: true,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sectionGap),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: viewModel.isCreating
                                ? null
                                : () => context.pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: AppSpacing.small),
                          TextButton(
                            onPressed: viewModel.isCreating
                                ? null
                                : () => _resetForm(viewModel),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  void _resetForm(PointOfPurchaseViewModel viewModel) {
    FocusScope.of(context).unfocus();
    setState(() {
      for (final controller in _fields.values) {
        controller.clear();
      }
      _fields['tare15kgsbag']?.text = '0';
      for (final bag in _bags) {
        bag.dispose();
      }
      _bags
        ..clear()
        ..add(_BagDraft(1));
      for (final payment in _cashPayments) {
        payment.dispose();
      }
      _cashPayments.clear();
      _nextBagNumber = 2;
      _links.clear();
      _supplier = null;
      _deliveryType = null;
      _productType = null;
      _purchaseDate = DateTime.now();
      _purchaseTime = TimeOfDay.now();
      _instantPaid = false;
      _formKey = GlobalKey<FormState>();
      _purchaseItemKey = GlobalKey<FormFieldState<bool>>();
    });
    viewModel.clearCreateError();
    viewModel.clearSupplierAdvances();
  }

  Widget _supplierSection(PointOfPurchaseViewModel viewModel) => AppCard(
    tone: AppCardTone.primary,
    showAccentBar: false,
    title: 'Supplier and collection',
    leading: const AppSvgIcon(icon: AppIconName.supplier),
    child: _fieldGrid([
      _selectField(
        label: 'Product Type',
        value: _productType,
        options: const ['Copra', 'Cocoa'],
        onChanged: (value) {
          setState(() => _productType = value);
          _purchaseItemKey.currentState?.didChange(true);
        },
      ),
      _linkField(
        viewModel,
        'collection_location',
        'Collection Location',
        'Warehouse',
      ),
      _supplierField(viewModel),
      _readOnlyValue('Supplier Name', _fieldText('supplier_name1')),
      _textField('village', 'Village', required: true),
      _textField('province', 'Province', required: true),
      _readOnlyValue('Supplier Type', _fieldText('supplier_type')),

      _linkField(viewModel, 'island', 'Island', 'Island'),
      _textField('phonemobile_no', 'Phone/Mobile No.'),
    ]),
  );

  Widget _supplierField(PointOfPurchaseViewModel viewModel) =>
      _optionsLoading(viewModel) && viewModel.supplierOptions.isEmpty
      ? const _OptionSkeleton(label: 'Supplier Code *')
      : AppDropdown<String>(
          value: _supplier,
          label: 'Supplier Code *',
          hint: 'Select a supplier',
          enabled: !_optionsLoading(viewModel),
          items: _dropdownItems(viewModel.supplierOptions),
          validator: (value) => value == null ? 'Select a supplier.' : null,
          onChanged: (value) {
            if (value == _supplier) return;
            setState(() {
              _supplier = value;
              _controller('advances').clear();
              final selected = _findOption(viewModel.supplierOptions, value);
              _controller('supplier_name1').text =
                  selected?['title']?.toString() ?? '';
              _controller('supplier_type').text =
                  selected?['supplier_type']?.toString() ?? '';
              _controller('village').text =
                  selected?['village']?.toString() ?? '';
              _controller('province').text =
                  selected?['province']?.toString() ?? '';
              _controller('phonemobile_no').text =
                  selected?['custom_contact_number']?.toString() ??
                  selected?['mobile_no']?.toString() ??
                  '';
              final island = selected?['custom_island']?.toString();
              if (island != null &&
                  viewModel
                      .linkOptions('Island')
                      .any((option) => option['value'] == island)) {
                _links['island'] = island;
              } else {
                _links['island'] = null;
              }
            });
            viewModel.clearCreateError();
            unawaited(viewModel.loadSupplierAdvances(value));
          },
        );

  Widget _deliverySection(PointOfPurchaseViewModel viewModel) => AppCard(
    tone: AppCardTone.info,
    showAccentBar: false,
    title: 'Purchase and delivery',
    leading: const AppSvgIcon(icon: AppIconName.purchase),
    child: _fieldGrid([
      _dateField(),
      _timeField(),
      _readOnlyValue(
        'POP Datetime',
        '${_formatDate(_purchaseDate)} ${_formatTime(_purchaseTime)}',
      ),
      _linkField(viewModel, 'company', 'Company *', 'Company', required: true),
      _selectField(
        label: 'Delivery Type',
        value: _deliveryType,
        options: const ['Hand Carry', 'Courier', 'Dealer'],
        onChanged: (value) => setState(() => _deliveryType = value),
      ),
      _textField('courier_name', 'Courier Name'),
      _textField('ffa', 'FFA'),
      _textField('moisture', 'Moisture'),
      _textField('copra_bag_level', 'Copra Bag Level'),
      _textField('contract_no', 'Contract No.'),
      _textField('ref_pv_no', 'Ref. PV No.'),
    ]),
  );

  Widget _pricingSection(PointOfPurchaseViewModel viewModel) => AppCard(
    tone: AppCardTone.warning,
    showAccentBar: false,
    title: 'Pricing and deductions',
    leading: const AppSvgIcon(icon: AppIconName.inventory),
    child: _fieldGrid([
      _textField(
        'rate',
        'Rate/kg *',
        required: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: _requiredNumber,
      ),
      _textField(
        'freight',
        'Freight Amount (\$)',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: _optionalNumber,
      ),
      _textField(
        'others',
        'Others (\$)',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: _optionalNumber,
      ),
      _textField(
        'sea_fare',
        'Sea Fare (\$)',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: _optionalNumber,
      ),
      // _readOnlyValue('Total Amount (\$)', _money(_itemTotal)),
      // _readOnlyValue('Grand Total (\$)', _money(_grandTotal)),
      // _readOnlyValue('Ship Payment (\$)', 'Calculated by ERP'),
      // _readOnlyValue('Total Deduction (\$)', _money(_deductionTotal)),

      // _textField(
      //   'net_payable',
      //   'Net Payable (\$)',
      //   keyboardType: const TextInputType.numberWithOptions(decimal: true),
      //   validator: _optionalNumber,
      // ),
      _availableAdvance(viewModel),
      _textField(
        'advances',
        'Advances Deduction (\$)',
        autovalidateMode: AutovalidateMode.always,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: viewModel.validateAdvanceDeduction,
      ),
    ]),
  );

  Widget _paymentAndAccountsSection(
    PointOfPurchaseViewModel viewModel,
  ) => AppCard(
    tone: AppCardTone.success,
    showAccentBar: false,
    title: 'Payment and accounts',
    leading: const AppSvgIcon(icon: AppIconName.inventory),
    child: Column(
      children: [
        _fieldGrid([
          _linkField(
            viewModel,
            'mode_of_payment',
            'Mode of Payment',
            'Mode of Payment',
            required: _grandTotal > 0,
          ),
          _textField(
            'payment_amount',
            'Payment Amount (\$)',
            required: _grandTotal > 0,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _grandTotal > 0 ? _requiredNumber : _optionalNumber,
          ),
          _linkField(
            viewModel,
            'default_accepted_warehouse',
            'Default Accepted Warehouse *',
            'Warehouse',
            required: true,
          ),
          _linkField(viewModel, 'vesel', 'Vessel', 'Supplier'),
          _readOnlyValue(
            'Vessel Name',
            _findOption(
                  viewModel.supplierOptions,
                  _links['vesel'],
                )?['title']?.toString() ??
                '',
          ),
          // Row(
          //   children: [
          //     Expanded(
          //       child: _linkField(
          //         viewModel,
          //         'bank_account',
          //         'Bank Account',
          //         'Account',
          //       ),
          //     ),
          //     const SizedBox(width: AppSpacing.medium),
          //     Expanded(
          //       child: _linkField(
          //         viewModel,
          //         'cash_account',
          //         'Cash Account',
          //         'Account',
          //       ),
          //     ),
          //   ],
          // ),

          // _linkField(viewModel, 'bank_account', 'Bank Account', 'Account'),
          // _linkField(viewModel, 'cash_account', 'Cash Account', 'Account'),

          // Row(
          //   children: [
          //     Expanded(
          //       child: _linkField(
          //         viewModel,
          //         'inventory_account',
          //         'Inventory Account',
          //         'Account',
          //       ),
          //     ),
          //     const SizedBox(width: AppSpacing.medium),
          //     Expanded(
          //       child: _linkField(
          //         viewModel,
          //         'advance_receivable_account',
          //         'Advance Receivable Account',
          //         'Account',
          //       ),
          //     ),
          //   ],
          // ),
          // _linkField(
          //   viewModel,
          //   'inventory_account',
          //   'Inventory Account',
          //   'Account',
          // ),
          // _linkField(
          //   viewModel,
          //   'advance_receivable_account',
          //   'Advance Receivable Account',
          //   'Account',
          // ),
          // _readOnlyValue('Paid To', 'Set by ERP'),
          // _readOnlyValue('Paid From', 'Set by ERP'),
          // _readOnlyValue('Other/Shipping Account', 'Set by ERP'),
          // _readOnlyValue('Amended From', 'Only for amended records'),
        ]),
        const SizedBox(height: AppSpacing.medium),
        AppCheckbox(
          value: _instantPaid,
          label: 'Is Paid',
          onChanged: (value) {
            setState(() {
              _instantPaid = value ?? false;
              if (_instantPaid && _cashPayments.isEmpty) {
                _cashPayments.add(_CashPaymentDraft());
              }
            });
          },
        ),
      ],
    ),
  );

  Widget _erpFieldsSection(PointOfPurchaseViewModel viewModel) => AppCard(
    tone: AppCardTone.neutral,
    showAccentBar: false,
    title: 'Additional information',
    subtitle: 'References and optional record details',
    leading: const AppSvgIcon(icon: AppIconName.inventory),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldGrid([
          _readOnlyValue('Series', 'CPV-.YY.-.#####'),
          _linkField(
            viewModel,
            'cashbank_account',
            'Cash/Bank Account',
            'Account',
          ),
          _linkField(
            viewModel,
            'journal_entry',
            'Journal Entry',
            'Journal Entry',
          ),
          _readOnlyValue('Paid', 'No (default)'),
          _readOnlyValue('GST (\$)', '0.00'),
          _readOnlyValue('Total Tare', 'Calculated by ERP'),
          _readOnlyValue('Purchase Invoice', 'Created or linked by ERP'),
          _readOnlyValue('Payment Entry', 'Created or linked by ERP'),
          _readOnlyValue('QR Code', 'Generated by ERP'),
          _readOnlyValue('Redirect QR Code', 'Generated by ERP'),
        ]),
        const SizedBox(height: AppSpacing.small),
        Text(
          'Read-only and hidden DocType values are managed by the ERP. The two link fields can be selected when needed.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );

  Widget _dateField() => _pickerField(
    label: 'Date',
    value:
        '${_purchaseDate.year}-${_twoDigits(_purchaseDate.month)}-${_twoDigits(_purchaseDate.day)}',
    onTap: () async {
      final date = await showDatePicker(
        context: context,
        initialDate: _purchaseDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (date != null) setState(() => _purchaseDate = date);
    },
  );

  Widget _timeField() => _pickerField(
    label: 'Time',
    value: _purchaseTime.format(context),
    onTap: () async {
      final time = await showTimePicker(
        context: context,
        initialTime: _purchaseTime,
      );
      if (time != null) setState(() => _purchaseTime = time);
    },
  );

  Widget _pickerField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppDimensions.fieldRadius),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Padding(
          padding: EdgeInsets.all(12),
          child: AppSvgIcon(icon: AppIconName.expandMore, size: 18),
        ),
      ),
      child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
    ),
  );

  Widget _fieldGrid(List<Widget> fields) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth >= 520 &&
              MediaQuery.textScalerOf(context).scale(14) <= 18
          ? 2
          : 1;
      final gap = AppSpacing.medium;
      final width = (constraints.maxWidth - (columns - 1) * gap) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final field in fields) SizedBox(width: width, child: field),
        ],
      );
    },
  );

  Widget _textField(
    String fieldname,
    String label, {
    bool required = false,
    String? initialValue,
    AutovalidateMode? autovalidateMode,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) => AppTextField(
    controller: _controller(fieldname, initialValue: initialValue),
    label: label,
    required: required,
    autovalidateMode: autovalidateMode,
    keyboardType: keyboardType,
    validator: validator ?? (required ? _required : null),
    onChanged: (_) {
      setState(() {});
      context.read<PointOfPurchaseViewModel>().clearCreateError();
    },
  );

  Widget _linkField(
    PointOfPurchaseViewModel viewModel,
    String fieldname,
    String label,
    String doctype, {
    bool required = false,
  }) {
    final options = doctype == 'Supplier'
        ? viewModel.supplierOptions
        : viewModel.linkOptions(doctype);
    if (_optionsLoading(viewModel) && options.isEmpty) {
      return _OptionSkeleton(label: label);
    }
    if (fieldname == 'company' &&
        _links[fieldname] == null &&
        options.isNotEmpty) {
      _links[fieldname] = options.first['value']?.toString();
    }
    return AppDropdown<String>(
      value: _links[fieldname],
      label: label,
      hint: 'Select ${label.replaceAll(' *', '').toLowerCase()}',
      enabled: !_optionsLoading(viewModel),
      items: _dropdownItems(options),
      validator: required
          ? (value) =>
                value == null ? 'Select ${label.replaceAll(' *', '')}.' : null
          : null,
      onChanged: (value) {
        setState(() {
          _links[fieldname] = value;
          if (fieldname == 'collection_location') {
            _links['default_accepted_warehouse'] = value;
          }
        });
        viewModel.clearCreateError();
      },
    );
  }

  Widget _selectField({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) => AppDropdown<String>(
    value: value,
    label: label,
    hint: 'Select ${label.toLowerCase()}',
    items: [
      for (final option in options)
        DropdownMenuItem<String>(value: option, child: Text(option)),
    ],
    onChanged: onChanged,
  );

  Widget _readOnlyValue(String label, String value) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    ),
    child: Text(
      value.isEmpty ? '-' : value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium,
    ),
  );

  TextEditingController _controller(String fieldname, {String? initialValue}) =>
      _fields.putIfAbsent(
        fieldname,
        () => TextEditingController(text: initialValue ?? ''),
      );

  String _fieldText(String fieldname) => _fields[fieldname]?.text.trim() ?? '';

  List<DropdownMenuItem<String>> _dropdownItems(
    List<Map<String, dynamic>> options,
  ) => [
    for (final option in options)
      DropdownMenuItem<String>(
        value: option['value'] as String,
        child: Text(
          option['label'] as String,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
  ];

  Map<String, dynamic>? _findOption(
    List<Map<String, dynamic>> options,
    String? value,
  ) {
    for (final option in options) {
      if (option['value'] == value) return option;
    }
    return null;
  }

  double _calculationValue(String value) {
    final number = double.tryParse(value.trim());
    return number != null && number.isFinite && number >= 0 ? number : 0;
  }

  double get _ratePerKg => _calculationValue(_fieldText('rate'));
  double get _itemTotal => _grossWeight * _ratePerKg;

  double get _grandTotal => _itemTotal;

  double get _grossWeight => _bags.fold<double>(
    0,
    (sum, row) => sum + _calculationValue(row.weight.text),
  );

  double get _deductionTotal =>
      _number(_fieldText('freight')) +
      _number(_fieldText('others')) +
      _number(_fieldText('sea_fare')) +
      _number(_fieldText('advances'));

  String _money(double value) => value.toStringAsFixed(2);

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  Widget _buildBagTable() => AppCard(
    tone: AppCardTone.success,
    showAccentBar: false,
    title: 'Bags and weight',
    subtitle: '${_bags.length} ${_bags.length == 1 ? 'row' : 'rows'}',
    leading: const AppSvgIcon(icon: AppIconName.inventory),
    trailing: _AddRowButton(
      onPressed: () => setState(() => _bags.add(_BagDraft(_nextBagNumber++))),
    ),
    child: Column(
      children: [
        _fieldGrid([
          _readOnlyValue('No. of Bag', _bags.length.toString()),
          _readOnlyValue('Gross Weight (kg)', _money(_grossWeight)),
          _textField(
            'tare15kgsbag',
            'Tare per bag (kg)',
            initialValue: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _optionalNumber,
          ),
        ]),
        const SizedBox(height: AppSpacing.medium),
        for (var index = 0; index < _bags.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.medium),
          _EditorRow(
            title: 'Bag ${index + 1}',
            onRemove: _bags.length == 1
                ? null
                : () => setState(() => _bags.removeAt(index).dispose()),
            child: Column(
              children: [
                AppTextField(
                  controller: _bags[index].number,
                  label: 'Bag number',
                  required: true,
                  validator: _required,
                  onChanged: (_) => context
                      .read<PointOfPurchaseViewModel>()
                      .clearCreateError(),
                ),
                const SizedBox(height: AppSpacing.medium),
                AppTextField(
                  controller: _bags[index].weight,
                  label: 'Weight (kg)',
                  required: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _requiredNumber,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.medium),
                AppTextField(
                  controller: _bags[index].tare,
                  label: 'Bag tare (kg)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _optionalNumber,
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  CalculatedPurchaseItem? _calculatedItem(PointOfPurchaseViewModel viewModel) {
    final item = CalculatedPurchaseItem.matchProduct(
      viewModel.itemOptions,
      _productType,
    );
    if (item == null) return null;
    return CalculatedPurchaseItem(
      itemCode: item['value'].toString(),
      itemName: CalculatedPurchaseItem.itemNameForProduct(_productType)!,
      weightKg: _grossWeight,
      ratePerKg: _ratePerKg,
    );
  }

  String? _purchaseItemError(PointOfPurchaseViewModel viewModel) {
    if (_productType == null) {
      return 'Select a product type to calculate its purchase item.';
    }
    if (_optionsLoading(viewModel)) {
      return 'Wait for the purchase items to load.';
    }
    if (_calculatedItem(viewModel) == null) {
      return 'The configured item ${CalculatedPurchaseItem.itemNameForProduct(_productType)} could not be uniquely found in the ERP item list.';
    }
    if (!_itemTotal.isFinite ||
        !(_ratePerKg * 1000).isFinite ||
        !_grossWeight.isFinite) {
      return 'The bag weight or rate is too large.';
    }
    return null;
  }

  Widget _buildItemTable(PointOfPurchaseViewModel viewModel) => FormField<bool>(
    key: _purchaseItemKey,
    validator: (_) => _purchaseItemError(viewModel),
    // Revalidate a previous submission error when the product or options change.
    autovalidateMode: AutovalidateMode.onUserInteraction,
    builder: (field) {
      final item = _calculatedItem(viewModel);
      return AppCard(
        tone: AppCardTone.primary,
        showAccentBar: false,
        title: 'Supplier POP Item',
        subtitle: 'Calculated automatically from bag weights and Rate/kg',
        leading: const AppSvgIcon(icon: AppIconName.purchase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_optionsLoading(viewModel))
              const SkeletonShimmer(
                label: 'Loading purchase item...',
                child: SkeletonBox(height: 96),
              )
            else if (item == null)
              Text(
                _purchaseItemError(viewModel)!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: field.hasError
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      showCheckboxColumn: false,
                      horizontalMargin: 12,
                      columnSpacing: 24,
                      headingRowColor: WidgetStatePropertyAll(
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      columns: const [
                        DataColumn(label: Text('No.')),
                        DataColumn(label: Text('Item Code')),
                        DataColumn(label: Text('Item Name')),
                        DataColumn(label: Text('Qty (MT)'), numeric: true),
                        DataColumn(label: Text('UOM')),
                        DataColumn(label: Text('Rate/MT'), numeric: true),
                        DataColumn(label: Text('Total Amount'), numeric: true),
                      ],
                      rows: [
                        DataRow(
                          cells: [
                            const DataCell(Text('1')),
                            DataCell(SelectableText(item.itemCode)),
                            DataCell(Text(item.itemName)),
                            DataCell(Text(item.quantityMt.toStringAsFixed(5))),
                            const DataCell(Text('MT')),
                            DataCell(
                              Text(
                                '\$ ${AppNumberFormat.amount(item.ratePerMt)}',
                              ),
                            ),
                            DataCell(
                              Text(
                                '\$ ${AppNumberFormat.amount(item.totalAmount)}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (field.hasError && item != null) ...[
              const SizedBox(height: AppSpacing.small),
              Text(
                field.errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      );
    },
  );

  Widget _availableAdvance(PointOfPurchaseViewModel viewModel) {
    if (viewModel.isLoadingSupplierAdvances) {
      return InputDecorator(
        decoration: const InputDecoration(labelText: 'Available Advance (\$)'),
        child: const SkeletonShimmer(
          label: 'Loading supplier advance balance...',
          child: SkeletonBox(height: 20),
        ),
      );
    }
    if (viewModel.supplierAdvancesError != null) {
      return _MessagePanel(
        message: viewModel.supplierAdvancesError!,
        isError: true,
        action: TextButton(
          onPressed: () =>
              unawaited(viewModel.loadSupplierAdvances(_supplier, force: true)),
          child: const Text('Retry'),
        ),
      );
    }
    return _readOnlyValue(
      'Available Advance (\$)',
      _supplier == null
          ? 'Select a supplier'
          : _money(viewModel.availableAdvance),
    );
  }

  Widget _buildAdvanceTable(PointOfPurchaseViewModel viewModel) {
    final allocations = viewModel.allocateSupplierAdvances(
      _fieldText('advances'),
    );
    return AppCard(
      tone: AppCardTone.info,
      showAccentBar: false,
      title: 'Advance Table',
      subtitle:
          '${allocations.length} allocated ${allocations.length == 1 ? 'reference' : 'references'}',
      leading: const AppSvgIcon(icon: AppIconName.inventory),
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              showCheckboxColumn: false,
              columnSpacing: 24,
              horizontalMargin: 12,
              headingRowColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              columns: const [
                DataColumn(label: Text('No.')),
                DataColumn(label: Text('Reference Name')),
                DataColumn(label: Text('Remarks')),
                DataColumn(label: Text('Advance Amount'), numeric: true),
                DataColumn(label: Text('Allocated Amount'), numeric: true),
              ],
              rows: [
                for (var i = 0; i < allocations.length; i++)
                  DataRow(
                    cells: [
                      DataCell(Text('${i + 1}')),
                      DataCell(SelectableText(allocations[i].advance.name)),
                      DataCell(Text(allocations[i].advance.remarks)),
                      DataCell(
                        Text(
                          '\$ ${AppNumberFormat.amount(allocations[i].advance.unallocatedAmount)}',
                        ),
                      ),
                      DataCell(
                        Text(
                          '\$ ${AppNumberFormat.amount(allocations[i].allocatedAmount)}',
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCashPaymentTable(PointOfPurchaseViewModel viewModel) => AppCard(
    tone: AppCardTone.success,
    showAccentBar: false,
    title: 'Cash payments',
    subtitle:
        '${_cashPayments.length} ${_cashPayments.length == 1 ? 'row' : 'rows'}',
    leading: const AppSvgIcon(icon: AppIconName.inventory),
    trailing: _AddRowButton(
      onPressed: () => setState(() => _cashPayments.add(_CashPaymentDraft())),
    ),
    child: Column(
      children: [
        for (var index = 0; index < _cashPayments.length; index++) ...[
          if (index > 0) const SizedBox(height: AppSpacing.medium),
          _EditorRow(
            title: 'Payment ${index + 1}',
            onRemove: _cashPayments.length == 1
                ? null
                : () => setState(() => _cashPayments.removeAt(index).dispose()),
            child: Column(
              children: [
                _selectField(
                  label: 'Payment Type',
                  value: _cashPayments[index].paymentType,
                  options: const ['Cash', 'Bank'],
                  onChanged: (value) => setState(
                    () => _cashPayments[index].paymentType = value ?? 'Cash',
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                AppTextField(
                  controller: _cashPayments[index].paidAmount,
                  label: 'Paid Amount',
                  required: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _requiredNumber,
                ),
                const SizedBox(height: AppSpacing.medium),
                AppTextField(
                  controller: _cashPayments[index].dueAmount,
                  label: 'Due Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _optionalNumber,
                ),
                const SizedBox(height: AppSpacing.medium),
                AppTextField(
                  controller: _cashPayments[index].bankPaymentAmount,
                  label: 'Bank Payment Amount',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _optionalNumber,
                ),
                const SizedBox(height: AppSpacing.medium),
                _optionsLoading(viewModel) &&
                        viewModel.linkOptions('Account').isEmpty
                    ? const _OptionSkeleton(label: 'Payment From')
                    : AppDropdown<String>(
                        value: _cashPayments[index].paymentFrom,
                        label: 'Payment From',
                        hint: 'Select an account',
                        enabled: !_optionsLoading(viewModel),
                        items: _dropdownItems(viewModel.linkOptions('Account')),
                        validator: (value) =>
                            value == null ? 'Select a payment account.' : null,
                        onChanged: (value) => setState(
                          () => _cashPayments[index].paymentFrom = value,
                        ),
                      ),
                const SizedBox(height: AppSpacing.small),
                AppCheckbox(
                  value: _cashPayments[index].checkKnlg,
                  label: 'Check acknowledged',
                  onChanged: (value) => setState(
                    () => _cashPayments[index].checkKnlg = value ?? false,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  Future<void> _submit(PointOfPurchaseViewModel viewModel) async {
    FocusScope.of(context).unfocus();
    viewModel.clearCreateError();
    if (!await validateAndReveal(_formKey) || !mounted) return;

    final supplier = viewModel.supplierOptions.firstWhere(
      (option) => option['value'] == _supplier,
    );
    final vessel = _findOption(viewModel.supplierOptions, _links['vesel']);
    final item = _calculatedItem(viewModel)!;
    final itemRows = [item.toJson()];
    final cashPaymentRows = [
      for (final row in _cashPayments)
        {
          'payment_type': row.paymentType,
          'due_amount': _number(row.dueAmount.text),
          'bank_payment_amount': _number(row.bankPaymentAmount.text),
          'payment_from': row.paymentFrom,
          'paid_amount': _number(row.paidAmount.text),
          'check_knlg': row.checkKnlg ? 1 : 0,
        },
    ];
    final date = _formatDate(_purchaseDate);
    final time = _formatTime(_purchaseTime);
    final netPayable = _fieldText('net_payable').isEmpty
        ? (_grandTotal - _deductionTotal).clamp(0, double.infinity)
        : _number(_fieldText('net_payable'));
    final payload = <String, dynamic>{
      'naming_series': 'CPV-.YY.-.#####',
      'supplier_name': _supplier,
      'supplier_name1': supplier['title'],
      'supplier_type': supplier['supplier_type'],
      'village': _fieldText('village'),
      'province': _fieldText('province'),
      'collection_location': _links['collection_location'],
      'island': _links['island'],
      'phonemobile_no': _fieldText('phonemobile_no'),
      'ffa': _fieldText('ffa'),
      'delivery_type': _deliveryType,
      'custom_product_type': _productType,
      'courier_name': _fieldText('courier_name'),
      'moisture': _fieldText('moisture'),
      'copra_bag_level': _fieldText('copra_bag_level'),
      'no_of_bag': _bags.length,
      'gross_weight': _grossWeight,
      'total_bag': [
        for (final row in _bags)
          {
            'bag_number': row.number.text.trim(),
            'weight': _number(row.weight.text),
            'tarebagkg': _number(row.tare.text),
          },
      ],
      'supplier_pop_item': itemRows,
      'rate': _number(_fieldText('rate')),
      'default_accepted_warehouse': _links['default_accepted_warehouse'],
      'vesel': _links['vesel'],
      'vesel_name': vessel?['title'],
      'date': date,
      'company': _links['company'],
      'freight': _number(_fieldText('freight')),
      'others': _number(_fieldText('others')),
      'tare15kgsbag': _number(_fieldText('tare15kgsbag')),
      'sea_fare': _number(_fieldText('sea_fare')),
      'total_amount': _itemTotal,
      'grand_total': _grandTotal,
      'total_deduction': _deductionTotal,
      'advances': _number(_fieldText('advances')),
      'net_payable': netPayable,
      'contract_no': _fieldText('contract_no'),
      'ref_pv_no': _fieldText('ref_pv_no'),
      'mode_of_payment': _links['mode_of_payment'],
      'payment_amount': _number(_fieldText('payment_amount')),
      'paid': 0,
      'gst': 0,
      'instant_paid': _instantPaid ? 1 : 0,
      'bank_account': _links['bank_account'],
      'cash_account': _links['cash_account'],
      'cashbank_account': _links['cashbank_account'],
      'inventory_account': _links['inventory_account'],
      'advance_receivable_account': _links['advance_receivable_account'],
      'journal_entry': _links['journal_entry'],
      'time': time,
      'pop_datetime': '$date $time',
      'net_qty': item.quantityMt,
      'supplier_advance_allocation': [
        for (final row in viewModel.allocateSupplierAdvances(
          _fieldText('advances'),
        ))
          row.toJson(),
      ],
      if (_instantPaid) 'pop_cash_payment': cashPaymentRows,
    };
    payload.removeWhere(
      (key, value) =>
          value == null || (value is String && value.trim().isEmpty),
    );

    final created = await viewModel.createPointOfPurchase(payload);
    if (!mounted) return;
    if (created) {
      context.pop(true);
    } else {
      AppSnackbar.show(
        context,
        viewModel.createErrorMessage ?? 'Unable to save purchase.',
        type: AppMessageType.error,
      );
    }
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  String? _requiredNumber(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter an amount.';
    return _optionalNumber(value);
  }

  String? _optionalNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = double.tryParse(value.trim());
    if (number == null || !number.isFinite) return 'Enter a valid number.';
    if (number < 0) return 'Enter zero or a positive number.';
    return null;
  }

  double _number(String value) => double.tryParse(value.trim()) ?? 0;

  String _formatDate(DateTime value) =>
      '${value.year}-${_twoDigits(value.month)}-${_twoDigits(value.day)}';

  String _formatTime(TimeOfDay value) =>
      '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}:00';
}

class _BagDraft {
  _BagDraft(int number)
    : number = TextEditingController(text: 'Bag - $number'),
      weight = TextEditingController(),
      tare = TextEditingController();

  final TextEditingController number;
  final TextEditingController weight;
  final TextEditingController tare;

  void dispose() {
    number.dispose();
    weight.dispose();
    tare.dispose();
  }
}

class _CashPaymentDraft {
  String paymentType = 'Cash';
  String? paymentFrom;
  bool checkKnlg = false;
  final dueAmount = TextEditingController();
  final bankPaymentAmount = TextEditingController();
  final paidAmount = TextEditingController();

  void dispose() {
    dueAmount.dispose();
    bankPaymentAmount.dispose();
    paidAmount.dispose();
  }
}

class _AddRowButton extends StatelessWidget {
  const _AddRowButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: const AppSvgIcon(icon: AppIconName.add, size: 18),
    label: const Text('Add'),
  );
}

class _EditorRow extends StatelessWidget {
  const _EditorRow({required this.title, required this.child, this.onRemove});

  final String title;
  final Widget child;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          if (onRemove != null)
            IconButton(
              tooltip: 'Remove $title',
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline, size: 20),
            ),
        ],
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.message,
    required this.isError,
    this.action,
  });

  final String message;
  final bool isError;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = isError ? colors.error : colors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: color),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

class _OptionSkeleton extends StatelessWidget {
  const _OptionSkeleton({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 4),
      const SkeletonBox(
        height: AppDimensions.fieldHeight,
        borderRadius: BorderRadius.all(
          Radius.circular(AppDimensions.fieldRadius),
        ),
      ),
    ],
  );
}
