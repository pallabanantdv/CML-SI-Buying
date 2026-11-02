import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../shared/widgets/app_app_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header_title.dart';
import '../../../shared/widgets/app_page_banner.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../viewmodels/supplier_viewmodel.dart';

class CreateSupplierScreen extends StatefulWidget {
  const CreateSupplierScreen({super.key});

  @override
  State<CreateSupplierScreen> createState() => _CreateSupplierScreenState();
}

class _CreateSupplierScreenState extends State<CreateSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _groupController;
  String _supplierType = 'Company';
  late final TextEditingController _countryController;
  late final TextEditingController _provinceController;
  late final TextEditingController _islandController;
  late final TextEditingController _villageController;
  late final TextEditingController _contactController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SupplierViewModel>().clearError();
    });
    _nameController = TextEditingController();
    _groupController = TextEditingController(text: 'Other');
    _countryController = TextEditingController(text: 'Solomon Islands');
    _provinceController = TextEditingController();
    _islandController = TextEditingController();
    _villageController = TextEditingController();
    _contactController = TextEditingController();
    _mobileController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _groupController.dispose();
    _countryController.dispose();
    _provinceController.dispose();
    _islandController.dispose();
    _villageController.dispose();
    _contactController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const AppAppBar(title: AppHeaderTitle(title: 'Add supplier')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppDimensions.formMaxWidth),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.pageGutter),
            children: [
              AppPageBanner(
                eyebrow: 'Supplier setup',
                title: 'Create a supplier',
                description:
                    'Add the profile, location, and contact information.',
                icon: AppIconName.add,
              ),
              const SizedBox(height: AppSpacing.large),
              AppCard(
                tone: AppCardTone.primary,
                showAccentBar: true,
                title: 'Supplier details',
                leading: AppSvgIcon(
                  icon: AppIconName.supplier,
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Column(
                  children: [
                    _field(
                      controller: _nameController,
                      label: 'Supplier name',
                      hint: 'Enter supplier or company name',
                      required: true,
                      validator: _required,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    _field(
                      controller: _groupController,
                      label: 'Supplier group',
                      hint: 'For example, Other',
                      required: true,
                      validator: _required,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    DropdownButtonFormField<String>(
                      initialValue: _supplierType,
                      decoration: const InputDecoration(
                        labelText: 'Supplier type',
                      ),
                      icon: AppSvgIcon(icon: AppIconName.expandMore, size: 18),
                      items: const [
                        DropdownMenuItem(
                          value: 'Company',
                          child: Text('Company'),
                        ),
                        DropdownMenuItem(
                          value: 'Individual',
                          child: Text('Individual'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _supplierType = value);
                          context.read<SupplierViewModel>().clearError();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.standard),
              AppCard(
                tone: AppCardTone.info,
                showAccentBar: true,
                title: 'Location and contact',
                leading: AppSvgIcon(
                  icon: AppIconName.person,
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Column(
                  children: [
                    _field(
                      controller: _countryController,
                      label: 'Country',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    _field(
                      controller: _provinceController,
                      label: 'Province',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    _field(
                      controller: _islandController,
                      label: 'Island',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    _field(
                      controller: _villageController,
                      label: 'Village',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    _field(
                      controller: _contactController,
                      label: 'Contact number',
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    _field(
                      controller: _mobileController,
                      label: 'Mobile number',
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AppSpacing.standard),
                    _field(
                      controller: _emailController,
                      label: 'Email address',
                      keyboardType: TextInputType.emailAddress,
                      validator: _emailValidator,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.standard),
              Consumer<SupplierViewModel>(
                builder: (context, viewModel, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (viewModel.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer
                              .withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.badgeRadius,
                          ),
                        ),
                        child: Row(
                          children: [
                            AppSvgIcon(
                              icon: AppIconName.info,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                            const SizedBox(width: AppSpacing.small),
                            Expanded(
                              child: Text(
                                viewModel.errorMessage!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onErrorContainer,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                    ],
                    AppButton(
                      label: 'Create supplier',
                      icon: AppIconName.add,
                      isLoading: viewModel.isSaving,
                      onPressed: viewModel.isSaving ? null : _submit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xLarge),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) => AppTextField(
    controller: controller,
    label: label,
    hint: hint,
    required: required,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    validator: validator,
    onChanged: (_) => context.read<SupplierViewModel>().clearError(),
  );

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required.' : null;

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
        ? null
        : 'Enter a valid email address.';
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final fields = <String, dynamic>{
      'supplier_name': _nameController.text.trim(),
      'supplier_group': _groupController.text.trim(),
      'supplier_type': _supplierType,
      'country': _countryController.text.trim(),
      'province': _provinceController.text.trim(),
      'custom_island': _islandController.text.trim(),
      'village': _villageController.text.trim(),
      'custom_contact_number': _contactController.text.trim(),
      'mobile_no': _mobileController.text.trim(),
      'email_id': _emailController.text.trim(),
    };
    fields.removeWhere((_, value) => value is String && value.isEmpty);

    final created = await context.read<SupplierViewModel>().createSupplier(
      fields,
    );
    if (created && mounted) context.pop(true);
  }
}
