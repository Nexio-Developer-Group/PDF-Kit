// lib/presentation/pages/pdf_to_image_page.dart

import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/component/pdf_page_selector.dart';
import 'package:pdf_kit/presentation/layouts/layout_export.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/service/pdf_to_image_service.dart';
import 'package:pdf_kit/service/path_service.dart';
import 'package:pdf_kit/service/recent_file_service.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/pages/home_page.dart';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'dart:io';

class PdfToImagePage extends StatefulWidget {
  final String? selectionId;

  const PdfToImagePage({super.key, this.selectionId});

  @override
  State<PdfToImagePage> createState() => _PdfToImagePageState();
}

class _PdfToImagePageState extends State<PdfToImagePage> {
  late final TextEditingController _nameCtrl;
  bool _isConverting = false;
  FileInfo? _selectedDestinationFolder;
  bool _isLoadingDefaultFolder = true;
  bool _isPageSelectorMode = false;

  Set<int> _selectedPages = {};
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _loadDefaultDestination();
    // PDF to image requires exactly 1 PDF file
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        SelectionScope.of(context).setMinSelectable(1);
        SelectionScope.of(context).setMaxSelectable(1);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Load default destination folder (Downloads)
  Future<void> _loadDefaultDestination() async {
    setState(() => _isLoadingDefaultFolder = true);

    try {
      final publicDirsResult = await PathService.publicDirs();

      publicDirsResult.fold(
        (error) {
          debugPrint('Failed to load default destination: $error');
          setState(() => _isLoadingDefaultFolder = false);
        },
        (publicDirs) {
          final downloadsDir = publicDirs['Downloads'];
          if (downloadsDir != null) {
            setState(() {
              _selectedDestinationFolder = FileInfo(
                name: 'Downloads',
                path: downloadsDir.path,
                extension: '',
                size: 0,
                isDirectory: true,
                lastModified: DateTime.now(),
              );
              _isLoadingDefaultFolder = false;
            });
          } else {
            setState(() => _isLoadingDefaultFolder = false);
          }
        },
      );
    } catch (e) {
      debugPrint('Error loading default destination: $e');
      setState(() => _isLoadingDefaultFolder = false);
    }
  }

  /// Open folder picker and update destination
  Future<void> _selectDestinationFolder() async {
    final selectedPath = await context.pushNamed<String>(
      AppRouteName.folderPickScreen,
    );

    if (selectedPath != null && mounted) {
      setState(() {
        _selectedDestinationFolder = FileInfo(
          name: selectedPath.split('/').last,
          path: selectedPath,
          extension: '',
          size: 0,
          isDirectory: true,
          lastModified: DateTime.now(),
        );
      });

      if (mounted) {
        final t = AppLocalizations.of(context);
        final msg = t
            .t('pdf_to_image_destination_snackbar')
            .replaceAll('{folderName}', _selectedDestinationFolder!.name);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
        );
      }
    }
  }

  String _displayName(FileInfo f) {
    try {
      final dynamic maybeName = (f as dynamic).name;
      if (maybeName is String && maybeName.trim().isNotEmpty) return maybeName;
    } catch (_) {}
    return p.basenameWithoutExtension(f.path);
  }

  String _suggestDefaultName(FileInfo file) {
    final baseName = _displayName(file);
    return '${baseName}_image';
  }

  String? get _pageSelectionSummaryText {
    if (_selectedPages.isEmpty || _totalPages == 0) {
      return null;
    }

    final pages = _selectedPages.toList()..sort();
    final ranges = <String>[];

    int start = pages.first;
    int prev = pages.first;

    for (final p in pages.skip(1)) {
      if (p == prev + 1) {
        prev = p;
      } else {
        if (start == prev) {
          ranges.add('$start');
        } else {
          ranges.add('$start-$prev');
        }
        start = prev = p;
      }
    }

    if (start == prev) {
      ranges.add('$start');
    } else {
      ranges.add('$start-$prev');
    }

    final rangesStr = ranges.join(', ');
    return '$rangesStr • ${_selectedPages.length} / $_totalPages pages selected';
  }

  Future<void> _handleConvert(
    BuildContext context,
    SelectionProvider selection,
  ) async {
    setState(() => _isConverting = true);

    final t = AppLocalizations.of(context);
    final files = selection.files;

    if (files.isEmpty) {
      setState(() => _isConverting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.t('pdf_to_image_no_file_error')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    final pdfFile = files.first;
    final outputName = _nameCtrl.text.trim().isEmpty
        ? _suggestDefaultName(pdfFile)
        : _nameCtrl.text.trim();

    // Get total page count for the PDF
    int totalPages = 0;
    try {
      final pdfDoc = await pdfx.PdfDocument.openFile(pdfFile.path);
      totalPages = pdfDoc.pagesCount;
      await pdfDoc.close();
    } catch (e) {
      debugPrint('Error getting page count: $e');
    }

    _totalPages = totalPages;

    // Use selected pages if any selection was made; otherwise, use all pages.
    List<int> pagesToConvert;
    if (_selectedPages.isEmpty) {
      pagesToConvert = List.generate(totalPages, (index) => index + 1);
    } else {
      pagesToConvert = _selectedPages.toList()..sort();
    }

    // Determine output directory - use the selected folder directly
    Directory? outputDir;
    if (_selectedDestinationFolder != null) {
      outputDir = Directory(_selectedDestinationFolder!.path);
    }

    final result =
        await PdfSelectedPagesToImagesService.exportSelectedPagesToImages(
          inputPdf: File(pdfFile.path),
          pageNumbers: pagesToConvert,
          outputDirectory: outputDir,
          fileNamePrefix: outputName, // Pass the prefix separately
        );

    setState(() => _isConverting = false);

    result.fold(
      (error) {
        if (!mounted) return;
        final msg = t
            .t('snackbar_error')
            .replaceAll('{message}', error.message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      (imageFiles) async {
        debugPrint('✅ [PdfToImage] Converted ${imageFiles.length} pages');

        // Add the first image to recent files
        if (imageFiles.isNotEmpty) {
          final firstImage = imageFiles.first;
          final firstImageInfo = FileInfo(
            name: p.basename(firstImage.path),
            path: firstImage.path,
            extension: p.extension(firstImage.path),
            size: await firstImage.length(),
            isDirectory: false,
            lastModified: await firstImage.lastModified(),
          );

          debugPrint(
            '📝 [PdfToImage] Adding first image to recent: ${firstImageInfo.name}',
          );
          final storeResult = await RecentFilesService.addRecentFile(
            firstImageInfo,
          );
          storeResult.fold(
            (error) => debugPrint('❌ [PdfToImage] Failed to store: $error'),
            (_) => debugPrint('✅ [PdfToImage] First image stored successfully'),
          );
        }

        if (!mounted) return;

        // Navigate to home and clear all routes
        selection.disable();
        context.go('/');

        // Trigger home page reload
        RecentFilesSection.refreshNotifier.value++;

        // Show success message after navigation
        Future.delayed(const Duration(milliseconds: 300), () {
          if (context.mounted) {
            final msg = t
                .t('snackbar_success_pdf_to_image')
                .replaceAll('{count}', imageFiles.length.toString())
                .replaceAll('{folderName}', outputName);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Consumer<SelectionProvider>(
      builder: (context, selection, _) {
        final files = selection.files;

        if (files.isNotEmpty &&
            (_nameCtrl.text.isEmpty ||
                _nameCtrl.text == t.t('pdf_to_image_default_name'))) {
          _nameCtrl.text = _suggestDefaultName(files.first);
          _nameCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _nameCtrl.text.length),
          );
        }

        return PopScope(
          canPop: !_isPageSelectorMode,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _isPageSelectorMode) {
              setState(() => _isPageSelectorMode = false);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_isPageSelectorMode) {
                    setState(() => _isPageSelectorMode = false);
                  } else {
                    context.pop();
                  }
                },
              ),
              actions: _isPageSelectorMode
                  ? [
                      TextButton(
                        onPressed: () {
                          setState(() => _isPageSelectorMode = false);
                        },
                        child: Text(t.t('common_done')),
                      ),
                    ]
                  : null,
            ),
            body: SafeArea(
              child: _isPageSelectorMode && files.isNotEmpty
                  ? Padding(
                      padding: screenPadding,
                      child: PdfPageSelector(
                        pdfFile: File(files.first.path),
                        initialSelectedPages: _selectedPages,
                        onSelectionChanged: (selected) {
                          setState(() {
                            _selectedPages = selected;
                          });
                        },
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.t('pdf_to_image_page_title'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t.t('pdf_to_image_page_description'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Image Name Field
                          Text(
                            t.t('pdf_to_image_name_label'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameCtrl,
                            enabled: !_isConverting,
                            decoration: InputDecoration(
                              hintText: t.t('pdf_to_image_name_hint'),
                              helperText: t.t('pdf_to_image_name_helper'),
                              helperMaxLines: 2,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(
                                Icons.drive_file_rename_outline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Destination Folder
                          Text(
                            t.t('pdf_to_image_destination_label'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _DestinationFolderSelector(
                            selectedFolder: _selectedDestinationFolder,
                            isLoading: _isLoadingDefaultFolder,
                            onTap: _selectDestinationFolder,
                            disabled: _isConverting,
                          ),
                          const SizedBox(height: 24),

                          // Selected PDF File + Select pages button in same row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.t('pdf_to_image_selected_file_label'),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: files.isEmpty
                                    ? null
                                    : () async {
                                        // Load total pages before entering selector mode
                                        try {
                                          final pdfDoc =
                                              await pdfx.PdfDocument.openFile(
                                                files.first.path,
                                              );
                                          _totalPages = pdfDoc.pagesCount;
                                          // Initialize all pages as selected if empty
                                          if (_selectedPages.isEmpty) {
                                            _selectedPages = Set.from(
                                              List.generate(
                                                _totalPages,
                                                (i) => i + 1,
                                              ),
                                            );
                                          }
                                          await pdfDoc.close();
                                          setState(() {
                                            _isPageSelectorMode = true;
                                          });
                                        } catch (e) {
                                          debugPrint('Error: $e');
                                        }
                                      },
                                icon: const Icon(Icons.filter_list),
                                label: Text(
                                  _selectedPages.isEmpty
                                      ? t.t('pdf_to_image_select_pages_button')
                                      : '${_selectedPages.length} ${t.t('pdf_to_image_pages_selected')}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (files.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: theme.colorScheme.outline.withOpacity(
                                    0.3,
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      t.t('pdf_to_image_no_file_selected'),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            DocEntryCard(
                              info: files.first,
                              onOpen: null,
                              onMenu: null,
                            ),
                            if (_pageSelectionSummaryText != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer
                                      .withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _pageSelectionSummaryText!,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isPageSelectorMode
                        ? () {
                            setState(() => _isPageSelectorMode = false);
                          }
                        : (files.isNotEmpty && !_isConverting)
                        ? () => _handleConvert(context, selection)
                        : null,
                    child: _isPageSelectorMode
                        ? Text(t.t('common_done'))
                        : _isConverting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(t.t('pdf_to_image_converting_button')),
                            ],
                          )
                        : Text(t.t('pdf_to_image_convert_button')),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Destination Folder Selector Widget
class _DestinationFolderSelector extends StatelessWidget {
  final FileInfo? selectedFolder;
  final bool isLoading;
  final VoidCallback onTap;
  final bool disabled;

  const _DestinationFolderSelector({
    required this.selectedFolder,
    required this.isLoading,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: disabled
                ? theme.colorScheme.onSurfaceVariant.withOpacity(0.15)
                : theme.colorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: isLoading
            ? Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    t.t('pdf_to_image_loading_default_folder'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Icon(
                    Icons.folder,
                    color: disabled
                        ? theme.colorScheme.onSurfaceVariant.withOpacity(0.4)
                        : theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedFolder?.name ??
                              t.t('pdf_to_image_select_folder_placeholder'),
                          style: theme.textTheme.bodyLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (selectedFolder != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            selectedFolder!.path,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(
                      disabled ? 0.3 : 1.0,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
