import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/presentation/layouts/selection_layout.dart';
import 'package:pdf_kit/service/pdf_split_service.dart';
import 'package:pdf_kit/service/recent_file_service.dart';
import 'package:pdf_kit/providers/file_system_provider.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/widgets/non_dismissible_progress_dialog.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_kit/presentation/pages/home_page.dart';
import 'package:pdf_kit/presentation/component/destination_folder_selector.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:pdf_kit/service/path_service.dart';

// Model for managing range widget state
class _RangeWidgetData {
  final TextEditingController startController;
  final TextEditingController endController;
  bool isActive;

  _RangeWidgetData({
    required this.startController,
    required this.endController,
    this.isActive = false,
  });

  void dispose() {
    startController.dispose();
    endController.dispose();
  }

  PageRange? toPageRange() {
    final start = int.tryParse(startController.text.trim());
    final end = int.tryParse(endController.text.trim());
    if (start != null && end != null && start > 0 && end > 0 && start <= end) {
      return PageRange(startPage: start, endPage: end);
    }
    return null;
  }

  bool get hasValues =>
      startController.text.trim().isNotEmpty &&
      endController.text.trim().isNotEmpty;
}

class SplitPdfPage extends StatefulWidget {
  final String? selectionId;

  const SplitPdfPage({super.key, this.selectionId});

  @override
  State<SplitPdfPage> createState() => _SplitPdfPageState();
}

class _SplitPdfPageState extends State<SplitPdfPage> {
  final TextEditingController _namingPatternController =
      TextEditingController();
  final List<_RangeWidgetData> _rangeWidgets = [];

  final ProgressDialogController _progressDialog = ProgressDialogController();

  bool _isSplitting = false;
  int? _totalPages;
  pdfx.PdfDocument? _pdfDocument;
  final List<Uint8List?> _pagePreviews = [];

  int _previewGenerationId = 0;
  bool _isAdjustingRange = false;

  String? _loadedPath;
  FileInfo? _selectedDestinationFolder;
  bool _isLoadingDefaultFolder = true;

  Future<void> _loadDefaultDestination(String sourcePath) async {
    setState(() => _isLoadingDefaultFolder = true);
    try {
      // Default to source file's parent directory
      final parentDir = Directory(p.dirname(sourcePath));
      if (await parentDir.exists()) {
        setState(() {
          _selectedDestinationFolder = FileInfo(
            name: p.basename(parentDir.path),
            path: parentDir.path,
            extension: '',
            size: 0,
            isDirectory: true,
            lastModified: DateTime.now(),
          );
          _isLoadingDefaultFolder = false;
        });
        return;
      }

      // Fallback to public Dir
      final publicDirsResult = await PathService.publicDirs();
      publicDirsResult.fold(
        (error) => setState(() => _isLoadingDefaultFolder = false),
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
    } catch (_) {
      setState(() => _isLoadingDefaultFolder = false);
    }
  }

  Future<void> _selectDestinationFolder() async {
    final t = AppLocalizations.of(context);
    final selectedPath = await context.pushNamed<String>(
      AppRouteName.folderPickScreen,
      extra: {
        'path': _selectedDestinationFolder?.path,
        'title': t.t('split_pdf_select_folder_title'),
        'description': t.t('split_pdf_select_folder_description'),
      },
    );
    if (selectedPath != null && mounted) {
      // Update local state only for Split Page as per requirements
      setState(() {
        _selectedDestinationFolder = FileInfo(
          name: p.basename(selectedPath),
          path: selectedPath,
          extension: '',
          size: 0,
          isDirectory: true,
          lastModified: DateTime.now(),
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _rangeWidgets.add(
      _RangeWidgetData(
        startController: TextEditingController(),
        endController: TextEditingController(),
        isActive: true,
      ),
    );
    _rangeWidgets.add(
      _RangeWidgetData(
        startController: TextEditingController(),
        endController: TextEditingController(),
        isActive: false,
      ),
    );

    // Add listeners to all range controllers for instant state updates
    for (var widget in _rangeWidgets) {
      widget.startController.addListener(_onRangeChanged);
      widget.endController.addListener(_onRangeChanged);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Keep this separate; never block PDF loading due to this.
      try {
        SelectionScope.of(context).setMinSelectable(1);
      } catch (e) {
        debugPrint('SelectionScope not found: $e');
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final selection = context.watch<SelectionProvider>();
    if (selection.files.isEmpty) return;

    final path = selection.files.first.path;
    if (_loadedPath == path) return; // already loaded this file

    _loadedPath = path;
    _loadPdfInfoForPath(path);
    _loadDefaultDestination(path);
  }

  @override
  void dispose() {
    _namingPatternController.dispose();
    for (var widget in _rangeWidgets) {
      widget.dispose();
    }
    _pdfDocument?.close();
    super.dispose();
  }

  Future<void> _loadPdfInfoForPath(String pdfPath) async {
    setState(() {
      _pagePreviews.clear();
      _totalPages = null;
    });

    try {
      await _pdfDocument?.close();
      _pdfDocument = null;

      final pageCountResult = await PdfSplitService.getPageCount(
        pdfPath: pdfPath,
      );

      await pageCountResult.fold(
        (error) async {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        (count) async {
          if (!mounted) return;

          setState(() {
            _totalPages = count;
            _namingPatternController.text = p.basenameWithoutExtension(pdfPath);
            // Show the preview strip immediately; pages will fill in progressively.
            _pagePreviews
              ..clear()
              ..addAll(List<Uint8List?>.filled(count, null));
          });

          _pdfDocument = await pdfx.PdfDocument.openFile(pdfPath);
          await _generatePagePreviews();
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() {});
    }
  }

  Future<void> _generatePagePreviews() async {
    if (_pdfDocument == null || _totalPages == null || _totalPages == 0) return;

    final generationId = ++_previewGenerationId;
    for (int i = 1; i <= _totalPages!; i++) {
      if (!mounted || generationId != _previewGenerationId) return;
      try {
        final page = await _pdfDocument!.getPage(i);
        final pageImage = await page.render(
          width: page.width * 0.3,
          height: page.height * 0.3,
          format: pdfx.PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
        );
        await page.close();
        if (!mounted || generationId != _previewGenerationId) return;

        if (i - 1 >= 0 && i - 1 < _pagePreviews.length) {
          _pagePreviews[i - 1] = pageImage?.bytes;
        }

        if (mounted) setState(() {});
      } catch (e) {
        if (!mounted || generationId != _previewGenerationId) return;
        if (i - 1 >= 0 && i - 1 < _pagePreviews.length) {
          _pagePreviews[i - 1] = null;
        }
        if (mounted) setState(() {});
      }
    }
  }

  void _activateRange(int index) {
    if (!_rangeWidgets[index].isActive) {
      setState(() {
        _rangeWidgets[index].isActive = true;
        // If this was the last widget, add another inactive one
        if (index == _rangeWidgets.length - 1) {
          final newWidget = _RangeWidgetData(
            startController: TextEditingController(),
            endController: TextEditingController(),
            isActive: false,
          );
          // Add listeners to new widget
          newWidget.startController.addListener(_onRangeChanged);
          newWidget.endController.addListener(_onRangeChanged);
          _rangeWidgets.add(newWidget);
        }
      });
    }
  }

  /// Called when any range controller value changes
  void _onRangeChanged() {
    if (_isAdjustingRange) return;
    _isAdjustingRange = true;
    try {
      for (final range in _rangeWidgets) {
        if (!range.isActive) continue;
        final start = int.tryParse(range.startController.text.trim());
        final end = int.tryParse(range.endController.text.trim());
        if (start == null || end == null) continue;

        if (end < start) {
          range.endController.text = start.toString();
          range.endController.selection = TextSelection.fromPosition(
            TextPosition(offset: range.endController.text.length),
          );
        }
      }
    } finally {
      _isAdjustingRange = false;
    }

    setState(() {
      // trigger rebuild and update button state
    });
  }

  void _removeRange(int index) {
    setState(() {
      _rangeWidgets[index].dispose();
      _rangeWidgets.removeAt(index);
    });
  }

  List<PageRange> _getValidRanges() {
    final ranges = <PageRange>[];
    for (var widget in _rangeWidgets) {
      if (widget.isActive) {
        final range = widget.toPageRange();
        if (range != null) {
          ranges.add(range);
        }
      }
    }
    return ranges;
  }

  Future<void> _handleSplit(
    BuildContext context,
    SelectionProvider selection,
  ) async {
    final ranges = _getValidRanges();

    if (ranges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one valid page range'),
        ),
      );
      return;
    }

    // Validate all ranges
    if (_totalPages != null) {
      final validationResult = PdfSplitService.validateRanges(
        ranges: ranges,
        totalPages: _totalPages!,
      );

      final error = validationResult.fold((err) => err, (_) => null);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
    }

    setState(() => _isSplitting = true);

    final file = selection.files.first;
    final pattern = _namingPatternController.text.trim();

    final progress = ValueNotifier<double>(0.0);
    final stage = ValueNotifier<String>('Starting…');
    Timer? creepTimer;

    late final SplitResult result;
    try {
      _progressDialog.show(
        context: context,
        title: 'Split PDF',
        progress: progress,
        stage: stage,
      );

      creepTimer = Timer.periodic(const Duration(milliseconds: 140), (_) {
        if (!mounted) return;
        if (progress.value < 0.98) {
          progress.value = (progress.value + 0.003).clamp(0.0, 0.98).toDouble();
        }
      });

      result = await PdfSplitService.splitPdf(
        sourcePdfPath: file.path,
        ranges: ranges,
        namingPattern: pattern.isNotEmpty ? pattern : null,
        outputDirectory: _selectedDestinationFolder?.path,
        onProgress: (p, s) {
          if (!mounted) return;
          stage.value = s;
          if (p > progress.value) progress.value = p.clamp(0.0, 1.0);
        },
      );

      if (mounted) {
        progress.value = 1.0;
        stage.value = 'Done';
        _progressDialog.dismiss(context);
      }
    } finally {
      creepTimer?.cancel();
      progress.dispose();
      stage.dispose();
      if (mounted) setState(() => _isSplitting = false);
    }

    if (!mounted) return;

    if (result.success) {
      final createdFiles = <FileInfo>[];
      String? downloadsPath;

      for (final outputPath in result.outputPaths) {
        try {
          final outputFile = File(outputPath);
          final stats = await outputFile.stat();
          final fileInfo = FileInfo(
            name: p.basename(outputPath),
            path: outputPath,
            size: stats.size,
            extension: 'pdf',
            lastModified: stats.modified,
            mimeType: 'application/pdf',
            parentDirectory: p.dirname(outputPath),
          );
          await RecentFilesService.addRecentFile(fileInfo);
          createdFiles.add(fileInfo);
          downloadsPath ??= p.dirname(outputPath);
        } catch (e) {
          debugPrint('Failed to add split file: $e');
        }
      }

      // Update FileSystemProvider to show files in Downloads folder
      if (downloadsPath != null && createdFiles.isNotEmpty) {
        try {
          final fileSystemProvider = context.read<FileSystemProvider>();
          await fileSystemProvider.addFiles(downloadsPath, createdFiles);
        } catch (e) {
          debugPrint('Failed to update FileSystemProvider: $e');
        }
      }

      selection.disable();
      context.go('/');
      RecentFilesSection.refreshNotifier.value++;

      // Show simple success snackbar instead of dialog
      Future.delayed(const Duration(milliseconds: 300), () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully split PDF into ${result.outputPaths.length} files',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Failed to split PDF'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<SelectionProvider>(
      builder: (context, selection, _) {
        final files = selection.files;
        final hasFile = files.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Split PDF',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select page ranges to extract from your PDF',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  if (hasFile) ...[
                    // Text(
                    //   'Selected PDF',
                    //   style: theme.textTheme.titleMedium?.copyWith(
                    //     fontWeight: FontWeight.w600,
                    //   ),
                    // ),
                    // const SizedBox(height: 12),
                    // DocEntryCard(
                    //   info: files.first,
                    //   showEdit: false,
                    //   showRemove: true,
                    //   selectable: false,
                    //   reorderable: false,
                    //   onOpen: null,
                    // ),
                    // const SizedBox(height: 24),

                    // Page Previews Section
                    if (_totalPages != null && _totalPages! > 0) ...[
                      Text('Page Preview', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _totalPages!,
                          itemBuilder: (context, index) {
                            final preview = index < _pagePreviews.length
                                ? _pagePreviews[index]
                                : null;
                            return Container(
                              width: 70,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: theme.colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(7),
                                      ),
                                      child: preview != null
                                          ? Image.memory(
                                              preview,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: theme
                                                  .colorScheme
                                                  .surfaceVariant,
                                            ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceVariant,
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(7),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: theme.textTheme.labelSmall,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    Text(
                      'Destination Folder',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    DestinationFolderSelector(
                      selectedFolder: _selectedDestinationFolder,
                      isLoading: _isLoadingDefaultFolder,
                      onTap: _selectDestinationFolder,
                      disabled: _isSplitting,
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'Output naming pattern',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _namingPatternController,
                      readOnly: _isSplitting,
                      decoration: InputDecoration(
                        hintText: 'filename_____',
                        helperText: _totalPages != null
                            ? 'Total pages: $_totalPages'
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Range Widgets Section
                    Text(
                      'Page Ranges',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._rangeWidgets.asMap().entries.map((entry) {
                      final index = entry.key;
                      final rangeWidget = entry.value;
                      return _RangeInputWidget(
                        index: index,
                        rangeWidget: rangeWidget,
                        totalPages: _totalPages,
                        isActive: rangeWidget.isActive,
                        isSplitting: _isSplitting,
                        onTap: () => _activateRange(index),
                        onRemove: () => _removeRange(index),
                      );
                    }),
                  ] else ...[
                    Row(
                      children: [
                        const Icon(Icons.picture_as_pdf_outlined, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'No PDF selected',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          bottomNavigationBar: hasFile
              ? Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(color: Colors.transparent),
                  child: SafeArea(
                    bottom: true,
                    minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: !_isSplitting && _getValidRanges().isNotEmpty
                            ? () => _handleSplit(context, selection)
                            : null,
                        child: _isSplitting
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
                                'Split PDF',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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

// Custom Range Input Widget
class _RangeInputWidget extends StatelessWidget {
  final int index;
  final _RangeWidgetData rangeWidget;
  final int? totalPages;
  final bool isActive;
  final bool isSplitting;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RangeInputWidget({
    required this.index,
    required this.rangeWidget,
    required this.totalPages,
    required this.isActive,
    required this.isSplitting,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opacity = isActive ? 1.0 : 0.4;

    return GestureDetector(
      onTap: !isActive ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.grey.shade200 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Opacity(
          opacity: opacity,
          child: Row(
            children: [
              // Range number indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isActive
                      ? theme.colorScheme.primary
                      : Colors.grey.shade400,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Start page input
              _CommonTextField(
                labelText: 'Start',
                hintText: '1',
                controller: rangeWidget.startController,
                enabled: isActive && !isSplitting,
                totalPages: totalPages,
              ),
              const SizedBox(width: 8),

              // End page input
              _CommonTextField(
                labelText: 'End',
                hintText: totalPages?.toString() ?? '',
                controller: rangeWidget.endController,
                enabled: isActive && !isSplitting,
                totalPages: totalPages,
                minController: rangeWidget.startController,
              ),
              const SizedBox(width: 4),

              // Remove button
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: isActive && !isSplitting ? onRemove : null,
                color: theme.colorScheme.error,
                iconSize: 16,
                padding: EdgeInsets.zero, // removes extra padding
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),

                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Common Text Field Widget
class _CommonTextField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final TextEditingController controller;
  final bool enabled;
  final int? totalPages;
  final TextEditingController? minController;

  const _CommonTextField({
    required this.labelText,
    required this.hintText,
    required this.controller,
    required this.enabled,
    this.totalPages,
    this.minController,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextField(
        controller: controller,
        enabled: enabled,
        // make the on focus border size and color change
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelStyle: Theme.of(context).textTheme.bodyMedium,
          labelText: labelText,
          hintText: hintText,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          focusedBorder: OutlineInputBorder(),

          isDense: true,
        ),
        cursorHeight: 18,
        cursorColor: Theme.of(context).colorScheme.secondary,
        onChanged: (value) {
          if (value.isNotEmpty) {
            final num = int.tryParse(value);
            if (num != null && totalPages != null) {
              if (num < 1) {
                controller.text = '1';
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length),
                );
              } else if (num > totalPages!) {
                controller.text = totalPages.toString();
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length),
                );
              }
            }

            final minText = minController?.text.trim();
            final minValue = minText == null ? null : int.tryParse(minText);
            if (minValue != null) {
              final current = int.tryParse(controller.text.trim());
              if (current != null && current < minValue) {
                controller.text = minValue.toString();
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length),
                );
              }
            }
          }
        },
      ),
    );
  }
}
