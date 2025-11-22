import 'package:flutter/material.dart';
import 'package:pdf_kit/presentation/models/setting_info_type.dart';

class SettingsTile extends StatelessWidget {
  final SettingsItem item;

  const SettingsTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    Widget? trailing;

    switch (item.type) {
      case SettingsItemType.navigation:
        trailing = const Icon(Icons.chevron_right);
        break;
      case SettingsItemType.value:
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.trailingText != null)
              Text(
                item.trailingText!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: item.leadingIcon != null
          ? Icon(item.leadingIcon, size: 30)
          : null,
      title: Text(item.title, style: Theme.of(context).textTheme.bodyLarge),
      subtitle: item.subtitle != null
          ? Text(item.subtitle!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: trailing,
      onTap: item.type == SettingsItemType.toggle ? null : item.onTap,
    );
  }
}
