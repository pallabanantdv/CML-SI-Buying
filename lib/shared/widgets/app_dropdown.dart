import 'package:flutter/material.dart';

import '../../config/theme/app_dimensions.dart';
import '../../config/theme/app_spacing.dart';
import 'app_svg_icon.dart';

class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.label,
    this.validator,
    this.enabled = true,
    this.hint,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String label;
  final String? Function(T?)? validator;
  final bool enabled;
  final String? hint;

  @override
  Widget build(BuildContext context) => FormField<T>(
    key: ValueKey(value),
    initialValue: value,
    validator: validator,
    builder: (field) {
      final selectedItem = _selectedItem(field.value);
      final canSelect = enabled && onChanged != null;

      return InkWell(
        onTap: canSelect
            ? () async {
                final selected = await showModalBottomSheet<T>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppDimensions.dialogRadius),
                    ),
                  ),
                  builder: (context) => _SearchableDropdownSheet<T>(
                    label: label.replaceAll(' *', '').trim(),
                    items: items,
                    selectedValue: field.value,
                  ),
                );

                if (selected == null || !context.mounted) return;
                field.didChange(selected);
                onChanged?.call(selected);
              }
            : null,
        borderRadius: BorderRadius.circular(AppDimensions.fieldRadius),
        child: InputDecorator(
          isFocused: false,
          isEmpty: selectedItem == null,
          decoration: InputDecoration(
            labelText: label,
            errorMaxLines: 3,
            hintText: hint,
            hintStyle: Theme.of(context).textTheme.labelMedium,
            enabled: canSelect,
            errorText: field.errorText,
            suffixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: AppSvgIcon(icon: AppIconName.expandMore, size: 18),
            ),
          ),
          child: selectedItem?.child ?? const SizedBox.shrink(),
        ),
      );
    },
  );

  DropdownMenuItem<T>? _selectedItem(T? selectedValue) {
    for (final item in items) {
      if (item.value == selectedValue) return item;
    }
    return null;
  }
}

class _SearchableDropdownSheet<T> extends StatefulWidget {
  const _SearchableDropdownSheet({
    required this.label,
    required this.items,
    required this.selectedValue,
  });

  final String label;
  final List<DropdownMenuItem<T>> items;
  final T? selectedValue;

  @override
  State<_SearchableDropdownSheet<T>> createState() =>
      _SearchableDropdownSheetState<T>();
}

class _SearchableDropdownSheetState<T>
    extends State<_SearchableDropdownSheet<T>> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.trim().toLowerCase();
    final filteredItems = widget.items
        .where((item) {
          if (!item.enabled) return false;
          return _searchText(item).toLowerCase().contains(query);
        })
        .toList(growable: false);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.standard,
                  AppSpacing.medium,
                  AppSpacing.standard,
                  AppSpacing.small,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select ${widget.label}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.standard,
                  vertical: AppSpacing.small,
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search ${widget.label.toLowerCase()}',
                    hintStyle: theme.textTheme.labelMedium,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12),
                      child: AppSvgIcon(icon: AppIconName.search, size: 20),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Text(
                          'No matching options',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          final selected = item.value == widget.selectedValue;
                          return ListTile(
                            selected: selected,
                            selectedColor: theme.colorScheme.primary,
                            title: DefaultTextStyle.merge(
                              style: theme.textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              child: item.child,
                            ),
                            onTap: () {
                              item.onTap?.call();
                              Navigator.of(context).pop<T>(item.value);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _searchText(DropdownMenuItem<T> item) {
    final child = item.child;
    String? childText;
    if (child is Text) {
      childText = child.data ?? child.textSpan?.toPlainText();
    } else if (child is RichText) {
      childText = child.text.toPlainText();
    }
    return '${childText ?? ''} ${item.value?.toString() ?? ''}';
  }
}
