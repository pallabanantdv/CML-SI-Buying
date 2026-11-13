import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/navigation/app_page_transitions.dart';
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
    this.onSearch,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String label;
  final String? Function(T?)? validator;
  final bool enabled;
  final String? hint;
  final Future<List<DropdownMenuItem<T>>> Function(String)? onSearch;

  @override
  Widget build(BuildContext context) {
    if (onSearch == null && items.where((item) => item.enabled).length < 10) {
      return DropdownButtonFormField<T>(
        key: ValueKey(value),
        initialValue: value,
        items: items,
        onChanged: enabled ? onChanged : null,
        validator: validator,
        isExpanded: true,
        style: Theme.of(context).textTheme.bodyMedium,
        borderRadius: BorderRadius.circular(AppDimensions.dialogRadius),
        dropdownColor: Theme.of(context).colorScheme.surface,
        icon: value == null
            ? const AppSvgIcon(icon: AppIconName.expandMore, size: 18)
            : IconButton(
                tooltip: 'Clear selection',
                icon: const Icon(Icons.close_rounded),
                onPressed: enabled && onChanged != null
                    ? () => onChanged?.call(null)
                    : null,
              ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: Theme.of(context).textTheme.labelSmall,
          floatingLabelStyle: Theme.of(context).textTheme.labelSmall,
          errorMaxLines: 3,
          hintText: hint,
          hintStyle: Theme.of(context).textTheme.labelMedium,
          enabled: enabled && onChanged != null,
        ),
      );
    }
    return FormField<T>(
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
                    sheetAnimationStyle: AppPageTransitions.modalStyle(context),
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
                      onSearch: onSearch,
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
              labelStyle: Theme.of(context).textTheme.labelSmall,
              floatingLabelStyle: Theme.of(context).textTheme.labelSmall,
              errorMaxLines: 3,
              hintText: hint,
              hintStyle: Theme.of(context).textTheme.labelMedium,
              enabled: canSelect,
              errorText: field.errorText,
              suffixIcon: field.value == null
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: AppSvgIcon(icon: AppIconName.expandMore, size: 18),
                    )
                  : IconButton(
                      tooltip: 'Clear selection',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: canSelect
                          ? () {
                              field.didChange(null);
                              onChanged?.call(null);
                            }
                          : null,
                    ),
            ),
            child: selectedItem == null
                ? const SizedBox.shrink()
                : DefaultTextStyle.merge(
                    style: Theme.of(context).textTheme.bodyMedium,
                    child: selectedItem.child,
                  ),
          ),
        );
      },
    );
  }

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
    this.onSearch,
  });

  final String label;
  final List<DropdownMenuItem<T>> items;
  final T? selectedValue;
  final Future<List<DropdownMenuItem<T>>> Function(String)? onSearch;

  @override
  State<_SearchableDropdownSheet<T>> createState() =>
      _SearchableDropdownSheetState<T>();
}

class _SearchableDropdownSheetState<T>
    extends State<_SearchableDropdownSheet<T>> {
  final _searchController = TextEditingController();
  String _query = '';
  Timer? _debounce;
  int _request = 0;
  bool _loading = false;
  bool _failed = false;
  List<DropdownMenuItem<T>>? _results;

  void _search(String value) {
    _debounce?.cancel();
    final request = ++_request;
    setState(() {
      _query = value;
      _loading = widget.onSearch != null;
      _failed = false;
    });
    if (widget.onSearch == null) return;
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final rows = await widget.onSearch!(value);
        if (!mounted || request != _request) return;
        setState(() {
          _results = rows;
          _loading = false;
        });
      } catch (_) {
        if (!mounted || request != _request) return;
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showSearch =
        widget.onSearch != null ||
        widget.items.where((item) => item.enabled).length >= 10;
    final query = _query.trim().toLowerCase();
    final filteredItems = (_results ?? widget.items)
        .where((item) {
          if (!item.enabled) return false;
          return widget.onSearch != null ||
              _searchText(item).toLowerCase().contains(query);
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
              if (showSearch)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.standard,
                    vertical: AppSpacing.small,
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: _search,
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
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _failed
                    ? Center(
                        child: TextButton(
                          onPressed: () => _search(_query),
                          child: const Text('Unable to load options. Retry'),
                        ),
                      )
                    : filteredItems.isEmpty
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
