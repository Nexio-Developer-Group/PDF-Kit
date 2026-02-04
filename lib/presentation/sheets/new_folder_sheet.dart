import 'package:flutter/material.dart';
import 'package:pdf_kit/core/localization/app_localizations.dart';

Future<void> showNewFolderSheet({
  required BuildContext context,
  String initialName = '',
  required ValueChanged<String>? onCreate,
}) {
  final controller = TextEditingController(text: initialName);

  debugPrint('[NewFolderSheet] Opening sheet; initialName="$initialName"');

  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final viewInsets = MediaQuery.of(ctx).viewInsets;
          final theme = Theme.of(ctx);

          void submitCreate() {
            final name = controller.text.trim();
            debugPrint(
              '[NewFolderSheet] Create tapped; raw="${controller.text}"; trimmed="$name"',
            );
            if (name.isEmpty) {
              debugPrint('[NewFolderSheet] Name empty; ignoring');
              return;
            }
            Navigator.of(ctx).maybePop();
            try {
              debugPrint(
                '[NewFolderSheet] Invoking onCreate callback with "$name"',
              );
              onCreate?.call(name);
            } catch (e) {
              debugPrint('[NewFolderSheet] onCreate threw: $e');
            }
          }

          return SafeArea(
            top: false,
            left: false,
            right: false,
            bottom: true,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + viewInsets.bottom),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  color: theme.dialogBackgroundColor,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 10,
                      bottom: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 4,
                          margin: const EdgeInsets.only(top: 0, bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.18,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Text(
                          AppLocalizations.of(
                            context,
                          ).t('new_folder_sheet_title'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          height: 1,
                          color: Theme.of(context).dividerColor.withAlpha(64),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppLocalizations.of(
                              context,
                            ).t('new_folder_field_label'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: controller,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: AppLocalizations.of(
                              context,
                            ).t('new_folder_field_hint'),
                            border: UnderlineInputBorder(),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFF3D5AFE),
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => submitCreate(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.of(ctx).maybePop(),
                                style: TextButton.styleFrom(
                                  backgroundColor: theme
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.3),
                                  foregroundColor: theme.colorScheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).t('common_cancel'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: controller.text.trim().isEmpty
                                    ? null
                                    : submitCreate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3D5AFE),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).t('new_folder_create_button'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() => debugPrint('[NewFolderSheet] Closed'));
}
