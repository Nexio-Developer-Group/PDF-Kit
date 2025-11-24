import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf_kit/core/localization/app_localizations.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// Shows a bottom sheet for drawing or importing a signature
Future<Uint8List?> showSignaturePickSheet({
  required BuildContext context,
}) async {
  return showModalBottomSheet<Uint8List>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _SignaturePickSheet(),
  );
}

class _SignaturePickSheet extends StatefulWidget {
  const _SignaturePickSheet();

  @override
  State<_SignaturePickSheet> createState() => _SignaturePickSheetState();
}

class _SignaturePickSheetState extends State<_SignaturePickSheet> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleImportImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) return;

      final bytes = await File(pickedFile.path).readAsBytes();

      if (mounted) {
        Navigator.of(context).pop(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error importing image: $e')));
      }
    }
  }

  Future<void> _handleAddSignature() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw a signature first')),
      );
      return;
    }

    final bytes = await _controller.toPngBytes();
    if (bytes != null && mounted) {
      Navigator.of(context).pop(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;

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
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  // Title
                  Text(
                    t.t('signature_sheet_title'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(height: 1, color: theme.dividerColor.withAlpha(64)),
                  const SizedBox(height: 16),

                  // Drawing area with fixed height
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Signature(
                        controller: _controller,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Clear button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _controller.clear(),
                      icon: const Icon(Icons.clear, size: 18),
                      label: Text(t.t('signature_sheet_clear')),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handleImportImage,
                          icon: const Icon(Icons.image, size: 18),
                          label: Text(t.t('signature_sheet_import')),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _handleAddSignature,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3D5AFE),
                            foregroundColor: Colors.white,
                            elevation: 4,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(t.t('signature_sheet_add')),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Cancel button
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface.withOpacity(
                        0.6,
                      ),
                    ),
                    child: Text(t.t('common_cancel')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
