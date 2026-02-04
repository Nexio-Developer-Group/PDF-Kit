import 'dart:io';
import 'package:dartz/dartz.dart' as dartz;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/core/exception/failures.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/presentation/layouts/selection_layout.dart';
import 'package:pdf_kit/service/pdf_protect_service.dart';
import 'package:pdf_kit/service/recent_file_service.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_kit/presentation/pages/home_page.dart';
import 'package:pdf_kit/presentation/widgets/non_dismissible_progress_dialog.dart';

class UnlockPdfPage extends StatefulWidget {
  final String? selectionId;

  const UnlockPdfPage({super.key, this.selectionId});

  @override
  State<UnlockPdfPage> createState() => _UnlockPdfPageState();
}

class _UnlockPdfPageState extends State<UnlockPdfPage> {
  @override
  void initState() {
    super.initState();
    // Unlock requires at least 1 selected file
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        SelectionScope.of(context).setMinSelectable(1);
      } catch (_) {}
    });
  }

  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = true;
  bool _isUnlocking = false;

  final ProgressDialogController _progressDialog = ProgressDialogController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleUnlock(
    BuildContext context,
    SelectionProvider selection,
  ) async {
    // Remove focus from text fields
    FocusScope.of(context).unfocus();

    final t = AppLocalizations.of(context);
    if (_passwordController.text.isEmpty) {
      AppSnackbar.showSnackBar(
        SnackBar(
          content: Text(t.t('unlock_pdf_error_enter_password')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (_isUnlocking) return;
    setState(() => _isUnlocking = true);

    final progress = ValueNotifier<double>(0.02);
    final stage = ValueNotifier<String>(t.t('progress_stage_preparing'));
    late final Timer smoothTimer;

    void bumpProgress(double value01) {
      final next = value01.clamp(0.0, 1.0);
      if (next > progress.value) progress.value = next;
    }

    _progressDialog.show(
      context: context,
      title: t.t('progress_dialog_unlocking_title'),
      progress: progress,
      stage: stage,
    );

    smoothTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (progress.value < 0.92) {
        bumpProgress(progress.value + 0.01);
      }
    });

    final file = selection.files.first;

    late final dartz.Either<Failure, String> result;
    try {
      // Get root isolate token for platform channel communication
      final rootIsolateToken = RootIsolateToken.instance!;

      // Run in isolate to prevent UI blocking
      result =
          await compute(
            _unlockPdfInIsolate,
            _UnlockParams(
              pdfPath: file.path,
              password: _passwordController.text,
              rootIsolateToken: rootIsolateToken,
            ),
          ).timeout(
            const Duration(minutes: 5),
            onTimeout: () => const dartz.Left(
              PdfProtectionFailure('error_failed_unlock_pdf'),
            ),
          );

      // Update progress manually since isolate can't call callbacks
      bumpProgress(0.9);
      stage.value = t.t('progress_stage_finalizing');
    } finally {
      try {
        bumpProgress(1.0);
        stage.value = t.t('progress_stage_done');
      } catch (_) {}

      smoothTimer.cancel();
      progress.dispose();
      stage.dispose();

      if (context.mounted) {
        _progressDialog.dismiss(context);
      }
      if (mounted) {
        setState(() => _isUnlocking = false);
      } else {
        _isUnlocking = false;
      }
    }

    if (!mounted) return;
    result.fold(
      (failure) {
        if (!mounted) return;
        final msg = t
            .t('snackbar_error')
            .replaceAll('{message}', t.t(failure.message));
        AppSnackbar.showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      (unlockedPath) async {
        final successMsg = t.t('snackbar_unlock_done');

        // Get updated file stats after unlocking
        final unlockedFileOnDisk = File(unlockedPath);
        final stats = await unlockedFileOnDisk.stat();

        // Update the file info with new metadata
        final updatedFile = FileInfo(
          name: p.basename(unlockedPath),
          path: unlockedPath,
          size: stats.size,
          extension: 'pdf',
          lastModified: stats.modified,
          mimeType: 'application/pdf',
          parentDirectory: p.dirname(unlockedPath),
        );

        // ✅ Store unlocked file to recent files
        await RecentFilesService.addRecentFile(updatedFile);

        if (!mounted) return;
        AppSnackbar.showSuccessWithOpen(
          message: successMsg,
          path: unlockedPath,
        );
        selection.disable();

        // ✅ Navigate to home and trigger refresh
        if (context.mounted) {
          context.go('/');
          RecentFilesSection.refreshNotifier.value++;
        }
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
        final t = AppLocalizations.of(context);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
              onPressed: () => context.pop(),
            ),
            centerTitle: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.t('unlock_pdf_title'),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t.t('unlock_pdf_description'),
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  // Selected PDF Section
                  if (hasFile) ...[
                    Text(
                      t.t('unlock_pdf_selected_file_label'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DocEntryCard(
                      info: files.first,
                      showViewerOptionsSheet: false,
                      showRemove: true,
                      selectable: false,
                      reorderable: false,
                      onOpen: null,
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    // No file selected - show placeholder
                    Row(
                      children: [
                        const Icon(Icons.picture_as_pdf_outlined, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            t.t('unlock_pdf_no_pdf_selected'),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Password Field (only show if file is selected)
                  if (hasFile) ...[
                    Text(
                      t.t('unlock_pdf_password_label'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      onChanged: (_) => setState(() {}),
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: t.t('unlock_pdf_password_hint'),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            setState(
                              () => _isPasswordVisible = !_isPasswordVisible,
                            );
                          },
                        ),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary,
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
              ? Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: const BoxDecoration(color: Colors.transparent),
                  child: SafeArea(
                    minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed:
                            !_isUnlocking && _passwordController.text.isNotEmpty
                            ? () => _handleUnlock(context, selection)
                            : null,
                        child: _isUnlocking
                            ? SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    theme.colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : Text(
                                t.t('unlock_pdf_button'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onPrimary,
                                ),
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

// Isolate-safe unlock parameters
class _UnlockParams {
  final String pdfPath;
  final String password;
  final RootIsolateToken rootIsolateToken;

  _UnlockParams({
    required this.pdfPath,
    required this.password,
    required this.rootIsolateToken,
  });
}

// Top-level function for isolate
Future<dartz.Either<Failure, String>> _unlockPdfInIsolate(
  _UnlockParams params,
) async {
  // Initialize binary messenger for platform channel communication
  BackgroundIsolateBinaryMessenger.ensureInitialized(params.rootIsolateToken);

  return await PdfProtectionService.unlockPdf(
    pdfPath: params.pdfPath,
    password: params.password,
    onProgress: null, // Can't use callbacks across isolates
  );
}
