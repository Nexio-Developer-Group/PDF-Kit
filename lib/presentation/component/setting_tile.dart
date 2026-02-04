import 'package:flutter/material.dart';
import 'package:pdf_kit/presentation/models/setting_info_type.dart';

class SettingsTile extends StatelessWidget {
  final SettingsItem item;

  const SettingsTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget? trailing;

    switch (item.type) {
      case SettingsItemType.navigation:
        trailing = Icon(
          Icons.chevron_right,
          color: colorScheme.onSurfaceVariant,
        );
        break;
      case SettingsItemType.value:
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.trailingText != null)
              Text(item.trailingText!, style: theme.textTheme.bodySmall),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        );
        break;
      case SettingsItemType.toggle:
        trailing = Switch(
          value: item.switchValue ?? false,
          onChanged: item.onChanged,
        );
        break;
      case SettingsItemType.info:
        trailing = null;
        break;
    }

    final leading = item.leadingIcon != null
        ? CircleAvatar(
            radius: 18,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              item.leadingIcon,
              size: 20,
              color: colorScheme.onPrimaryContainer,
            ),
          )
        : null;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: Theme.of(context).brightness == Brightness.light
            ? BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.15),
                width: 1,
              )
            : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: leading,
        title: Text(item.title, style: theme.textTheme.titleSmall),
        subtitle: item.subtitle != null
            ? Text(item.subtitle!, style: theme.textTheme.bodyMedium)
            : null,
        trailing: trailing,
        onTap: item.type == SettingsItemType.toggle ? null : item.onTap,
      ),
    );
  }
}
