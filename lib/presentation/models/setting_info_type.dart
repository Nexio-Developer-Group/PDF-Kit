import 'package:flutter/material.dart';

/// 🧾 Represents a single row in the Settings screen.
enum SettingsItemType {
  navigation,   // opens another screen
  toggle,       // on/off like Dark Mode
  value,        // shows current value on the right (e.g. language)
  info,         // just text, no interaction
}

class SettingsItem {
  final String id;
  final String title;
  final String? subtitle;
  final SettingsItemType type;

  /// For icon on the left (if you want it, can be null).
  final IconData? leadingIcon;

  /// For `value` type (e.g. "English (US)", "Custom").
  final String? trailingText;

  /// For `toggle` type.
  final bool? switchValue;

  /// Callback when tile is tapped.
  final VoidCallback? onTap;

  /// Callback when switch changed (for toggle).
  final ValueChanged<bool>? onChanged;

  const SettingsItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
    this.leadingIcon,
    this.trailingText,
    this.switchValue,
    this.onTap,
    this.onChanged,
  });

  SettingsItem copyWith({
    String? title,
    String? subtitle,
    SettingsItemType? type,
    IconData? leadingIcon,
    String? trailingText,
    bool? switchValue,
    VoidCallback? onTap,
    ValueChanged<bool>? onChanged,
  }) {
    return SettingsItem(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      type: type ?? this.type,
      leadingIcon: leadingIcon ?? this.leadingIcon,
      trailingText: trailingText ?? this.trailingText,
      switchValue: switchValue ?? this.switchValue,
      onTap: onTap ?? this.onTap,
      onChanged: onChanged ?? this.onChanged,
    );
  }
}
