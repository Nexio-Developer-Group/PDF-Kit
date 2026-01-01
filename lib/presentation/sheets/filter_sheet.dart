import 'package:flutter/material.dart';
import 'package:pdf_kit/presentation/models/filter_models.dart';
import 'package:pdf_kit/core/app_export.dart';

class FilterSheet extends StatefulWidget {
  final SortOption currentSort;
  final Set<TypeFilter> currentTypes;
  final String? currentFileType; // From functionality (all/pdf/images)
  final ValueChanged<SortOption> onSortChanged;
  final ValueChanged<Set<TypeFilter>> onTypeFiltersChanged;

  const FilterSheet({
    super.key,
    required this.currentSort,
    required this.currentTypes,
    this.currentFileType,
    required this.onSortChanged,
    required this.onTypeFiltersChanged,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late SortOption _sort;
  late Set<TypeFilter> _types;
  bool _showTypeOptions = false;

  @override
  void initState() {
    super.initState();
    _sort = widget.currentSort;
    _types = Set.from(widget.currentTypes);

    // If type filters are empty, initialize based on fileType
    if (_types.isEmpty) {
      if (widget.currentFileType == 'pdf') {
        // For PDF-only mode, show folders + PDFs
        _types.addAll([TypeFilter.folder, TypeFilter.pdf]);
      } else if (widget.currentFileType == 'images') {
        // For images-only mode, show folders + images
        _types.addAll([TypeFilter.folder, TypeFilter.image]);
      } else {
        // For 'all' or null, show everything
        _types.addAll([TypeFilter.folder, TypeFilter.pdf, TypeFilter.image]);
      }
    }
  }

  void _emitChanges() {
    widget.onSortChanged(_sort);
    widget.onTypeFiltersChanged(Set.from(_types));
  }

  // NEW: localized type summary for subtitle
  String _typeSummary(AppLocalizations t) {
    if (_types.isEmpty) {
      return t.t('filter_type_all');
    }

    final parts = <String>[];
    if (_types.contains(TypeFilter.folder)) {
      parts.add(t.t('filter_type_folders'));
    }
    if (_types.contains(TypeFilter.pdf)) {
      parts.add(t.t('filter_type_pdfs'));
    }
    if (_types.contains(TypeFilter.image)) {
      parts.add(t.t('filter_type_images'));
    }
    return parts.join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: theme.dialogBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: theme.shadowColor.withOpacity(0.25), blurRadius: 16),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.18),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                t.t('filter_sheet_title'), // was 'Sort & Filter'
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.15,
                ),
              ),
            ),
          ),
          const Divider(height: 24, thickness: 1),

          // Sort Options
          SelectableTile(
            selected: _sort == SortOption.name,
            label: t.t('filter_by_name'), // was 'By name'
            trailingIcon: Icons.sort_by_alpha,
            onTap: () {
              setState(() => _sort = SortOption.name);
              _emitChanges();
            },
          ),
          SelectableTile(
            selected: _sort == SortOption.modified,
            label: t.t('filter_by_modified'), // was 'By modified date'
            trailingIcon: Icons.update,
            onTap: () {
              setState(() => _sort = SortOption.modified);
              _emitChanges();
            },
          ),

          const Divider(height: 20),

          // Type Filter Header
          ListTile(
            contentPadding: const EdgeInsets.only(left: 12),
            minVerticalPadding: 0,
            title: Text(
              t.t('filter_type_header'), // was 'Type'
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              _typeSummary(t),
              style: TextStyle(fontSize: 13, color: theme.hintColor),
            ),
            leading: Icon(Icons.filter_list, color: theme.iconTheme.color),
            trailing: IconButton(
              icon: Icon(
                _showTypeOptions ? Icons.expand_less : Icons.expand_more,
              ),
              onPressed: () =>
                  setState(() => _showTypeOptions = !_showTypeOptions),
            ),
            onTap: () => setState(() => _showTypeOptions = !_showTypeOptions),
          ),

          if (_showTypeOptions)
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Column(
                children: [
                  SelectableTile(
                    selected: _types.contains(TypeFilter.folder),
                    label: t.t('filter_type_folders'), // was 'Folders'
                    trailingIcon: Icons.folder_outlined,
                    onTap: () {
                      setState(() {
                        final isSelected = _types.contains(TypeFilter.folder);
                        if (isSelected && _types.length == 1) return;
                        if (isSelected) {
                          _types.remove(TypeFilter.folder);
                        } else {
                          _types.add(TypeFilter.folder);
                        }
                      });
                      _emitChanges();
                    },
                  ),
                  SelectableTile(
                    selected: _types.contains(TypeFilter.pdf),
                    label: t.t('filter_type_pdfs'), // was 'PDFs'
                    trailingIcon: Icons.picture_as_pdf_outlined,
                    onTap: () {
                      setState(() {
                        final isSelected = _types.contains(TypeFilter.pdf);
                        if (isSelected && _types.length == 1) return;
                        if (isSelected) {
                          _types.remove(TypeFilter.pdf);
                        } else {
                          _types.add(TypeFilter.pdf);
                        }
                      });
                      _emitChanges();
                    },
                  ),
                  SelectableTile(
                    selected: _types.contains(TypeFilter.image),
                    label: t.t('filter_type_images'), // was 'Images'
                    trailingIcon: Icons.image_outlined,
                    onTap: () {
                      setState(() {
                        final isSelected = _types.contains(TypeFilter.image);
                        if (isSelected && _types.length == 1) return;
                        if (isSelected) {
                          _types.remove(TypeFilter.image);
                        } else {
                          _types.add(TypeFilter.image);
                        }
                      });
                      _emitChanges();
                    },
                  ),
                ],
              ),
            ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class SelectableTile extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData? trailingIcon;
  final VoidCallback onTap;
  final Color? highlightColor;

  const SelectableTile({
    Key? key,
    required this.selected,
    required this.label,
    this.trailingIcon,
    required this.onTap,
    this.highlightColor,
  }) : super(key: key);
  //
  @override
  Widget build(BuildContext context) {
    final Color resolvedHighlight =
        highlightColor ??
        Theme.of(context).colorScheme.primary.withOpacity(0.08);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        decoration: selected
            ? BoxDecoration(
                color: resolvedHighlight,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).iconTheme.color,
              ),
            ),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 16,
                ),
              ),
            ),
            if (trailingIcon != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  trailingIcon,
                  color: Theme.of(context).iconTheme.color?.withOpacity(0.7),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
