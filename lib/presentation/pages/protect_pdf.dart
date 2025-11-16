import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/service/pdf_protect_service.dart';
import 'package:pdf_kit/service/recent_file_service.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:path/path.dart' as p;

class ProtectPdfPage extends StatefulWidget {
  final String? selectionId;

  const ProtectPdfPage({super.key, this.selectionId});

  @override
  State<ProtectPdfPage> createState() => _ProtectPdfPageState();
}

class _ProtectPdfPageState extends State<ProtectPdfPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isProtecting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _displayName(FileInfo f) {
    try {
      final dynamic maybeName = (f as dynamic).name;
      if (maybeName is String && maybeName.trim().isNotEmpty) return maybeName;
    } catch (_) {}
    return p.basenameWithoutExtension(f.path);
  }

  /// 💾 Store protected file and source file to recent files
  Future<void> _storeRecentFiles(
    FileInfo protectedFile,
    FileInfo sourceFile,
  ) async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔒 [ProtectPDF] Starting storage of recent files');
    debugPrint('═══════════════════════════════════════════════════════');

    try {
      // 1️⃣ Add protected file first (most recent)
      debugPrint(
        '📝 [ProtectPDF] Storing protected file: ${protectedFile.name}',
      );
      debugPrint('   Path: ${protectedFile.path}');
      debugPrint('   Size: ${protectedFile.readableSize}');

      final protectedResult = await RecentFilesService.addRecentFile(
        protectedFile,
      );

      protectedResult.fold(
        (error) {
          debugPrint('❌ [ProtectPDF] Failed to store protected file: $error');
        },
        (updatedFiles) {
          debugPrint('✅ [ProtectPDF] Protected file stored successfully');
          debugPrint('   Total files in storage: ${updatedFiles.length}');
        },
      );

      debugPrint('');
      debugPrint('📚 [ProtectPDF] Storing source file:');
      debugPrint('   ${sourceFile.name}');

      // 2️⃣ Add source file
      final result = await RecentFilesService.addRecentFile(sourceFile);

      result.fold(
        (error) {
          debugPrint('   ❌ Failed: $error');
        },
        (updatedFiles) {
          debugPrint('   ✅ Stored (Total: ${updatedFiles.length})');
        },
      );

      debugPrint('');
      debugPrint('🎉 [ProtectPDF] All files storage completed!');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('');

      // Verify storage by reading back
      debugPrint('🔍 [ProtectPDF] Verifying storage...');
      final verifyResult = await RecentFilesService.getRecentFiles();
      verifyResult.fold(
        (error) {
          debugPrint('❌ [ProtectPDF] Verification failed: $error');
        },
        (files) {
          debugPrint('✅ [ProtectPDF] Verification successful!');
          debugPrint('   Files in storage: ${files.length}');
          for (var i = 0; i < files.length; i++) {
            debugPrint('   ${i + 1}. ${files[i].name}');
          }
        },
      );
      debugPrint('');
    } catch (e) {
      debugPrint('❌ [ProtectPDF] Error storing recent files: $e');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('');
    }
  }

  Future<void> _handleProtect(
    BuildContext context,
    SelectionProvider selection,
  ) async {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a password'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passwords do not match'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isProtecting = true);

    final file = selection.files.first;

    final result = await PdfProtectionService.protectPdf(
      pdfPath: file.path,
      password: _passwordController.text,
    );

    setState(() => _isProtecting = false);

    result.fold(
      (failure) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${failure.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      (protectedPath) async {
        // Create FileInfo for protected file
        final protectedFile = FileInfo(
          name: "atatat",
          path: protectedPath,
          size: 324,
          extension: "meow",
          lastModified: DateTime.now(),
        );

        // ✅ Store recent files after successful protection
        await _storeRecentFiles(protectedFile, file);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully protected ${p.basename(protectedPath)}',
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                context.pushNamed(
                  AppRouteName.showPdf,
                  queryParameters: {'path': protectedPath},
                );
              },
            ),
          ),
        );
        selection.disable();

        // ✅ Pass true to indicate success and trigger refresh
        context.pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<SelectionProvider>(
      builder: (context, selection, _) {
        final files = selection.files;
        final hasFile = files.isNotEmpty;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => context.pop(),
            ),
            centerTitle: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Protect PDF',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Set a password to protect your scan. This password will be required if you or the person you provide the scanned document wants to access the file. If you forget the password, then this file will not be accessible forever.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Selected PDF Section
                  if (hasFile) ...[
                    Text(
                      'Selected File',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DocEntryCard(
                      info: files.first,
                      showActions: true,
                      onRemove: () => selection.removeFile(files.first.path),
                      onOpen: () => context.pushNamed(
                        AppRouteName.showPdf,
                        queryParameters: {'path': files.first.path},
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Add PDF Button (only show if no file selected)
                  if (!hasFile) ...[
                    _AddPdfButton(
                      onTap: () {
                        final params = <String, String>{
                          'actionText': 'Select',
                          'singleSelection': 'true',
                        };
                        if (widget.selectionId != null) {
                          params['selectionId'] = widget.selectionId!;
                        }
                        context.pushNamed(
                          AppRouteName.filesRootFullscreen,
                          queryParameters: params,
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Password Fields (only show if file is selected)
                  if (hasFile) ...[
                    Text(
                      'Password',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: '••••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFF5B7FFF),
                          ),
                          onPressed: () {
                            setState(
                              () => _isPasswordVisible = !_isPasswordVisible,
                            );
                          },
                        ),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF5B7FFF),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Confirm Password',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        hintText: '••••••••••',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: const Color(0xFF5B7FFF),
                          ),
                          onPressed: () {
                            setState(
                              () => _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible,
                            );
                          },
                        ),
                        border: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF5B7FFF),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          bottomNavigationBar: hasFile
              ? SafeArea(
                  minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: !_isProtecting
                          ? () => _handleProtect(context, selection)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF5B7FFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: _isProtecting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Protect',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _AddPdfButton extends StatelessWidget {
  const _AddPdfButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                color: theme.colorScheme.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add PDF File',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
