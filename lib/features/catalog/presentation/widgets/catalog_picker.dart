import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// A dropdown-style field that opens a searchable picker sheet for a catalog
/// list (categories / brands). The sheet includes an "Add new" action so users
/// can create their own value without leaving the flow.
class CatalogPickerField extends StatelessWidget {
  final String label;
  final String noun; // singular, lowercase — e.g. "category", "brand"
  final String? value;
  final List<String> options;
  final bool loading;
  final ValueChanged<String> onSelected;
  final Future<String?> Function() onAddNew;

  const CatalogPickerField({
    super.key,
    required this.label,
    required this.noun,
    required this.value,
    required this.options,
    required this.loading,
    required this.onSelected,
    required this.onAddNew,
  });

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.topOnly),
      builder: (_) => _PickerSheet(
        noun: noun,
        value: value,
        options: options,
        onAddNew: onAddNew,
      ),
    );
    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.labelSmall.copyWith(
                color: palette.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 1.0)),
        const SizedBox(height: AppSpacing.space2),
        GestureDetector(
          onTap: () => _open(context),
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: AppRadius.md,
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? (loading ? 'Loading…' : 'Select $noun'),
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLarge.copyWith(
                      color: value != null ? palette.textPrimary : palette.textTertiary,
                    ),
                  ),
                ),
                Icon(Icons.expand_more, color: palette.textTertiary, size: AppSpacing.iconSm),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerSheet extends StatefulWidget {
  final String noun;
  final String? value;
  final List<String> options;
  final Future<String?> Function() onAddNew;

  const _PickerSheet({
    required this.noun,
    required this.value,
    required this.options,
    required this.onAddNew,
  });

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.options
        : widget.options.where((o) => o.toLowerCase().contains(q)).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.space2),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: palette.border, borderRadius: BorderRadius.circular(99)),
              ),
              Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select ${widget.noun}',
                        style: AppTypography.headingMedium.copyWith(color: palette.textPrimary)),
                    const SizedBox(height: AppSpacing.space3),
                    TextField(
                      autofocus: false,
                      onChanged: (v) => setState(() => _query = v),
                      style: AppTypography.bodyMedium.copyWith(color: palette.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Search ${widget.noun}s',
                        hintStyle: AppTypography.bodyMedium.copyWith(color: palette.textTertiary),
                        prefixIcon: Icon(Icons.search, size: AppSpacing.iconSm, color: palette.textTertiary),
                        filled: true,
                        fillColor: palette.surfaceAlt,
                        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.pill,
                          borderSide: BorderSide(color: palette.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.pill,
                          borderSide: BorderSide(color: palette.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.pill,
                          borderSide: BorderSide(color: palette.accent, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Add new
              ListTile(
                onTap: () async {
                  final created = await widget.onAddNew();
                  if (created != null && context.mounted) Navigator.pop(context, created);
                },
                leading: Icon(Icons.add, color: palette.accentStrong),
                title: Text('Add a new ${widget.noun}',
                    style: AppTypography.labelLarge.copyWith(color: palette.accentStrong)),
              ),
              Divider(height: 1, color: palette.border),
              Flexible(
                child: filtered.isEmpty
                    ? Padding(
                        padding: AppSpacing.paddingLg,
                        child: Text('No matches. Use "Add a new ${widget.noun}" above.',
                            style: AppTypography.bodyMedium.copyWith(color: palette.textTertiary)),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final o = filtered[i];
                          final selected = o == widget.value;
                          return ListTile(
                            onTap: () => Navigator.pop(context, o),
                            title: Text(o,
                                style: AppTypography.bodyLarge.copyWith(color: palette.textPrimary)),
                            trailing: selected
                                ? Icon(Icons.check, color: palette.accent, size: AppSpacing.iconSm)
                                : null,
                          );
                        },
                      ),
              ),
              const SizedBox(height: AppSpacing.space2),
            ],
          ),
        ),
      ),
    );
  }
}
