import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/models/filter_models.dart';

class FilterOptionsPage extends StatefulWidget {
  const FilterOptionsPage({super.key});

  @override
  State<FilterOptionsPage> createState() => _FilterOptionsPageState();
}

class _FilterOptionsPageState extends State<FilterOptionsPage> {
  static const _prefName = 'name';
  static const _prefModified = 'modified';

  late SortOption _selected;

  @override
  void initState() {
    super.initState();
    _selected = _sortFromPref(Prefs.getString(Constants.filesSortOptionKey));
  }

  SortOption _sortFromPref(String? value) {
    switch (value) {
      case _prefModified:
        return SortOption.modified;
      case _prefName:
      default:
        return SortOption.name;
    }
  }

  String _sortToPref(SortOption option) {
    switch (option) {
      case SortOption.modified:
        return _prefModified;
      case SortOption.name:
      case SortOption.type:
        return _prefName;
    }
  }

  void _setSort(SortOption option) {
    setState(() => _selected = option);
    Prefs.setString(Constants.filesSortOptionKey, _sortToPref(option));
  }

  Widget _buildSortOptionCard({
    required BuildContext context,
    required SortOption value,
    required String title,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isSelected = _selected == value;

    return InkWell(
      onTap: () => _setSort(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primaryContainer.withValues(alpha: 0.18)
              : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary.withValues(alpha: 0.12)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? cs.primary : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? cs.primary : null,
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? cs.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? cs.primary : cs.outlineVariant,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 16, color: cs.onPrimary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.t('settings_filter_options_title'),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                t.t('settings_filter_options_description'),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildSortOptionCard(
                context: context,
                value: SortOption.name,
                title: t.t('filter_by_name'),
                icon: Icons.sort_by_alpha,
              ),
              const SizedBox(height: 10),
              _buildSortOptionCard(
                context: context,
                value: SortOption.modified,
                title: t.t('filter_by_modified'),
                icon: Icons.schedule,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
