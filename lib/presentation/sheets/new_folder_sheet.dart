import 'package:flutter/material.dart';

Future<void> showNewFolderSheet({
  required BuildContext context,
  String initialName = '',
  required ValueChanged<String>? onCreate,
}) {
  final controller = TextEditingController(text: initialName);

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    clipBehavior: Clip.antiAlias, // keep rounded corners clean
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      final viewInsets = MediaQuery.of(ctx).viewInsets;
      final theme = Theme.of(ctx);
      return Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: SafeArea(
          top: false,
          child: Material(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  const Text(
                    'New Folder',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Label
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Folder Name',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Text field with underline style
                  TextField(
                    controller: controller,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Enter folder name',
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
                    onSubmitted: (_) {
                      final name = controller.text.trim();
                      if (name.isNotEmpty) {
                        Navigator.of(ctx).pop();
                        // onCreate(name);
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Buttons row
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: const Color(0xFFE9EDFF),
                            foregroundColor: const Color(0xFF3D5AFE),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final name = controller.text.trim();
                            if (name.isNotEmpty) {
                              Navigator.of(ctx).pop();
                              // onCreate(name);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3D5AFE),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('Create'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
