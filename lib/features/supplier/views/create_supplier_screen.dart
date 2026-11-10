import 'dart:async';
import 'dart:ui' as ui;

import '../../../core/errors/app_exception.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/theme/app_dimensions.dart';
import '../../../config/theme/app_spacing.dart';
import '../../../shared/widgets/app_app_bar.dart';
import '../../../shared/widgets/app_dropdown.dart';
import '../../../shared/widgets/app_form_action_bar.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header_title.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../viewmodels/supplier_viewmodel.dart';

class CreateSupplierScreen extends StatefulWidget {
  const CreateSupplierScreen({super.key, this.supplier});
  final Map<String, dynamic>? supplier;

  @override
  State<CreateSupplierScreen> createState() => _CreateSupplierScreenState();
}

class _CreateSupplierScreenState extends State<CreateSupplierScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressExpansionController = ExpansibleController();
  late final TextEditingController _nameController;
  late final TextEditingController _groupController;
  String _supplierType = 'Company';
  static const _supplierTypes = [
    'Company',
    'Individual',
    'Partnership',
    'Walk-in',
    'Agent',
    'Trading',
    'Vesel',
  ];
  static const _doctypes = ['Village', 'Island', 'Supplier Group', 'Province'];
  final _options = <String, List<String>>{};
  final _optionErrors = <String, String>{};
  final _loadingOptions = <String>{};

  Future<void> _loadOptions(String doctype) async {
    if (_loadingOptions.contains(doctype)) return;
    final repository = context.read<SupplierViewModel>().repository;
    setState(() {
      _loadingOptions.add(doctype);
      _optionErrors.remove(doctype);
    });
    try {
      final options = await repository.getSupplierFieldOptions(doctype);
      if (!mounted) return;
      setState(() => _options[doctype] = options);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _optionErrors[doctype] = error is AppException
            ? error.message
            : 'Unable to load $doctype. Please retry.',
      );
    } finally {
      if (mounted) setState(() => _loadingOptions.remove(doctype));
    }
  }

  Widget _linkDropdown(
    String doctype,
    TextEditingController controller, {
    bool required = false,
  }) {
    final options = {
      ...?_options[doctype],
      if (controller.text.isNotEmpty) controller.text,
    }.toList();
    final loading = _loadingOptions.contains(doctype);
    final error = _optionErrors[doctype];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDropdown<String>(
          key: ValueKey('$doctype-${options.join('|')}'),
          value: options.contains(controller.text) ? controller.text : null,
          label: '$doctype${required ? ' *' : ''}',
          hint: 'Select ${doctype.toLowerCase()}',
          enabled: !loading && options.isNotEmpty,
          items: [
            for (final option in options)
              DropdownMenuItem(
                value: option,
                child: Text(option, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: loading || options.isEmpty
              ? null
              : (value) {
                  setState(() => controller.text = value ?? '');
                  context.read<SupplierViewModel>().clearError();
                },
          validator: required ? _required : null,
        ),
        if (loading || (error == null && options.isEmpty))
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Text(
              loading ? 'Loading...' : 'No records available',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (error != null) ...[
          Text(
            error,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _loadOptions(doctype),
              child: Text('Retry $doctype'),
            ),
          ),
        ],
      ],
    );
  }

  Uint8List? _imageBytes;
  String? _imageFilename;
  bool _pickingImage = false;
  String? _existingImage;

  Future<void> _pickImage({
    bool fromGallery = true,
    bool camera = false,
  }) async {
    if (_pickingImage || context.read<SupplierViewModel>().isSaving) return;
    setState(() => _pickingImage = true);
    try {
      final Uint8List bytes;
      final String filename;
      if (fromGallery || camera) {
        final image = await ImagePicker().pickImage(
          source: camera ? ImageSource.camera : ImageSource.gallery,
          requestFullMetadata: false,
        );
        if (!mounted || image == null) return;
        bytes = await image.readAsBytes();
        filename = image.name;
      } else {
        final file = await FilePicker.pickFile(type: FileType.image);
        if (!mounted || file == null) return;
        bytes = await file.readAsBytes();
        filename = file.name;
      }
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        throw const FormatException('Choose an image smaller than 5 MB.');
      }
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 240);
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageFilename = filename;
      });
      context.read<SupplierViewModel>().clearError();
    } catch (error) {
      if (mounted) {
        AppSnackbar.show(
          context,
          error is MissingPluginException
              ? 'The image picker is not loaded. Stop the app completely and rebuild it, then try again.'
              : error is PlatformException
              ? 'Unable to open the photo picker: ${error.message ?? error.code}. Try Choose file instead.'
              : error is FormatException
              ? error.message
              : 'Unable to read this image. Try another photo or Choose file.',
          type: AppMessageType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  late final TextEditingController _countryController;
  late final TextEditingController _provinceController;
  late final TextEditingController _islandController;
  late final TextEditingController _villageController;
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  bool get _hasAddress => [
    _addressLine1Controller,
    _addressLine2Controller,
    _cityController,
    _stateController,
    _zipController,
  ].any((controller) => controller.text.trim().isNotEmpty);
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SupplierViewModel>().clearError();
        for (final doctype in _doctypes) {
          unawaited(_loadOptions(doctype));
        }
      }
    });
    _nameController = TextEditingController();
    _groupController = TextEditingController();
    _countryController = TextEditingController(text: 'Solomon Islands');
    _provinceController = TextEditingController();
    _islandController = TextEditingController();
    _villageController = TextEditingController();
    _mobileController = TextEditingController();
    _emailController = TextEditingController();
    final record = widget.supplier;
    if (record != null) {
      final controllers = <String, TextEditingController>{
        'supplier_name': _nameController,
        'supplier_group': _groupController,
        'country': _countryController,
        'province': _provinceController,
        'custom_island': _islandController,
        'village': _villageController,
        'mobile_no': _mobileController,
        'email_id': _emailController,
      };
      for (final entry in controllers.entries) {
        entry.value.text = '${record[entry.key] ?? ''}';
      }
      _supplierType = '${record['supplier_type'] ?? 'Company'}';
      _existingImage = record['image']?.toString();
    }
  }

  @override
  void dispose() {
    _addressExpansionController.dispose();
    _nameController.dispose();
    _groupController.dispose();
    _countryController.dispose();
    _provinceController.dispose();
    _islandController.dispose();
    _villageController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppAppBar(
      title: AppHeaderTitle(
        title: widget.supplier == null ? 'Add supplier' : 'Edit supplier',
      ),
    ),
    bottomNavigationBar: Consumer<SupplierViewModel>(
      builder: (context, vm, _) => AppFormActionBar(
        label: 'Save supplier',
        isLoading: vm.isSaving,
        onPressed: vm.isSaving || _pickingImage ? null : _submit,
      ),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppDimensions.formMaxWidth),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppDimensions.pageGutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Consumer<SupplierViewModel>(
                  builder: (context, vm, _) => AppCard(
                    title: 'Profile picture',
                    subtitle: 'Optional · JPG, PNG or WebP · Up to 5 MB',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: SizedBox.square(
                            dimension: 64,
                            child: _imageBytes != null
                                ? Image.memory(
                                    _imageBytes!,
                                    fit: BoxFit.cover,
                                    cacheWidth: 192,
                                    semanticLabel: 'Selected supplier image',
                                  )
                                : _existingImage?.isNotEmpty == true
                                ? Image.network(
                                    vm.repository.printServerUri
                                        .resolve(_existingImage!)
                                        .toString(),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.person_outline,
                                      size: 32,
                                    ),
                                  )
                                : ColoredBox(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child: const Icon(
                                      Icons.person_outline,
                                      size: 32,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            children: [
                              TextButton.icon(
                                onPressed: vm.isSaving || _pickingImage
                                    ? null
                                    : () => _pickImage(camera: true),
                                icon: const Icon(
                                  Icons.camera_alt_outlined,
                                  size: 18,
                                ),
                                label: const Text('Camera'),
                              ),
                              TextButton.icon(
                                onPressed: vm.isSaving || _pickingImage
                                    ? null
                                    : () => _pickImage(fromGallery: false),
                                icon: const Icon(
                                  Icons.folder_open_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  _pickingImage ? 'Opening...' : 'Choose file',
                                ),
                              ),
                              if (_imageBytes != null ||
                                  _existingImage?.isNotEmpty == true)
                                TextButton(
                                  onPressed: vm.isSaving || _pickingImage
                                      ? null
                                      : () => setState(() {
                                          _imageBytes = null;
                                          _imageFilename = null;
                                          _existingImage = '';
                                        }),
                                  child: const Text('Remove'),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
                AppCard(
                  tone: AppCardTone.primary,
                  showAccentBar: false,
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
                      const SizedBox(height: AppSpacing.sectionGap),
                      _linkDropdown(
                        'Supplier Group',
                        _groupController,
                        required: true,
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
                      AppDropdown<String>(
                        value: _supplierType,
                        label: 'Supplier type',
                        hint: 'Select supplier type',
                        items: [
                          for (final type in {..._supplierTypes, _supplierType})
                            DropdownMenuItem(value: type, child: Text(type)),
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
                const SizedBox(height: AppSpacing.sectionGap),
                AppCard(
                  tone: AppCardTone.info,
                  showAccentBar: false,
                  title: 'Location and contact',
                  leading: AppSvgIcon(
                    icon: AppIconName.person,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Column(
                    children: [
                      _linkDropdown('Province', _provinceController),
                      const SizedBox(height: AppSpacing.sectionGap),
                      _linkDropdown('Island', _islandController),
                      const SizedBox(height: AppSpacing.sectionGap),
                      _linkDropdown('Village', _villageController),
                      const SizedBox(height: AppSpacing.sectionGap),
                      _field(
                        controller: _mobileController,
                        label: 'Mobile number',
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sectionGap),
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
                const SizedBox(height: AppSpacing.sectionGap),
                if (widget.supplier == null)
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: ExpansionTile(
                      controller: _addressExpansionController,
                      initiallyExpanded: false,
                      maintainState: true,
                      shape: const Border(),
                      collapsedShape: const Border(),
                      title: Text(
                        'Primary Address Details',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(
                        AppSpacing.cardPadding,
                        0,
                        AppSpacing.cardPadding,
                        AppSpacing.cardPadding,
                      ),
                      children: [
                        Column(
                          children: [
                            _field(
                              controller: _addressLine1Controller,
                              label: 'Address Line 1',
                              validator: (value) =>
                                  _hasAddress ? _required(value) : null,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: AppSpacing.sectionGap),
                            _field(
                              controller: _addressLine2Controller,
                              label: 'Address Line 2',
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: AppSpacing.sectionGap),
                            _field(
                              controller: _zipController,
                              label: 'ZIP Code',
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: AppSpacing.sectionGap),
                            _field(
                              controller: _cityController,
                              label: 'City',
                              validator: (value) =>
                                  _hasAddress ? _required(value) : null,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: AppSpacing.sectionGap),
                            _field(
                              controller: _stateController,
                              label: 'State',
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: AppSpacing.sectionGap),
                            _field(
                              controller: _countryController,
                              label: 'Country',
                              required: true,
                              validator: _required,
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSpacing.sectionGap),
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
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sectionGap),
              ],
            ),
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
    if (_pickingImage || context.read<SupplierViewModel>().isSaving) return;
    FocusScope.of(context).unfocus();
    // Reveal invalid address fields before scrolling to the first form error.
    if ((_hasAddress &&
            (_required(_addressLine1Controller.text) != null ||
                _required(_cityController.text) != null)) ||
        _required(_countryController.text) != null) {
      _addressExpansionController.expand();
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
    if (!await validateAndReveal(_formKey) || !mounted) return;

    final fields = <String, dynamic>{
      'supplier_name': _nameController.text.trim(),
      'supplier_group': _groupController.text.trim(),
      'supplier_type': _supplierType,
      'country': _countryController.text.trim(),
      'province': _provinceController.text.trim(),
      'custom_island': _islandController.text.trim(),
      'village': _villageController.text.trim(),
      'address_line1': _addressLine1Controller.text.trim(),
      'address_line2': _addressLine2Controller.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _zipController.text.trim(),
      'mobile_no': _mobileController.text.trim(),
      'email_id': _emailController.text.trim(),
    };
    if (widget.supplier == null) {
      fields.removeWhere((_, value) => value is String && value.isEmpty);
    } else {
      // Address documents are separate from the Supplier record.
      for (final key in [
        'address_line1',
        'address_line2',
        'city',
        'state',
        'pincode',
      ]) {
        fields.remove(key);
      }
      fields.removeWhere(
        (key, value) => value == (widget.supplier![key] ?? ''),
      );
      if (_existingImage == '' && widget.supplier!['image'] != null) {
        fields['image'] = '';
      }
    }

    final created = await context.read<SupplierViewModel>().createSupplier(
      fields,
      imageBytes: _imageBytes,
      imageFilename: _imageFilename,
      supplierId: widget.supplier?['name']?.toString(),
    );
    if (!mounted) return;
    if (created) {
      context.pop(true);
    } else {
      AppSnackbar.show(
        context,
        context.read<SupplierViewModel>().errorMessage ??
            'Unable to save supplier.',
        type: AppMessageType.error,
      );
    }
  }
}
