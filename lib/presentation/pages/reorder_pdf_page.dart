import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf_kit/presentation/provider/provider_export.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/widgets/non_dismissible_progress_dialog.dart';
import 'package:pdf_kit/service/pdf_manipulation_service.dart';
import 'package:pdf_kit/service/recent_file_service.dart';
import 'package:pdf_kit/presentation/component/pdf_page_thumbnail.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:path/path.dart' as p;

import 'package:pdf_kit/service/path_service.dart';
import 'package:pdf_kit/presentation/pages/home_page.dart';

class ReorderPdfPage extends StatefulWidget {
  final String? selectionId;

  const ReorderPdfPage({super.key, this.selectionId});

  @override
  State<ReorderPdfPage> createState() => _ReorderPdfPageState();
}

class _ReorderPdfPageState extends State<ReorderPdfPage> {
  Set<int> _removedPages = {};
  Map<int, double> _rotations = {};
  List<int> _pageOrder = [];
  bool _isProcessing = false;
  bool _isLoading = true;
  int _totalPages = 0;
  final Map<int, Uint8List?> _pageCache = {};
  FileInfo? _selectedDestinationFolder;

  final ProgressDialogController _progressDialog = ProgressDialogController();

  Future<void> _loadDefaultDestination() async {
    try {
      final savedPath = Prefs.getString(Constants.pdfOutputFolderPathKey);
      if (savedPath != null) {
        final dir = Directory(savedPath);
        if (await dir.exists()) {
          setState(() {
            _selectedDestinationFolder = FileInfo(
              name: p.basename(savedPath),
              path: savedPath,
              extension: '',
              size: 0,
              isDirectory: true,
              lastModified: DateTime.now(),
            );
          });
          return;
        }
      }
      final publicDirsResult = await PathService.publicDirs();
      publicDirsResult.fold((error) {}, (publicDirs) {
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
          });
        }
      });
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _loadDefaultDestination();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPdfInfo();
    });
  }

  Future<void> _loadPdfInfo() async {
    final selection = context.read<SelectionProvider>();
    final files = selection.files;

    if (files.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final doc = await pdfx.PdfDocument.openFile(files.first.path);
      _totalPages = doc.pagesCount;
      _pageOrder = List.generate(_totalPages, (i) => i + 1);
      await doc.close();

      setState(() => _isLoading = false);

      // Start loading thumbnails
      _loadPageThumbnails(files.first.path);
    } catch (e) {
      debugPrint('❌ [ReorderPdfPage] Error loading PDF: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPageThumbnails(String pdfPath) async {
    try {
      final doc = await pdfx.PdfDocument.openFile(pdfPath);

      for (int pageNum = 1; pageNum <= _totalPages; pageNum++) {
        if (!mounted) break;
        if (_pageCache.containsKey(pageNum)) continue;

        try {
          final page = await doc.getPage(pageNum);
          final pageImage = await page.render(
            width: 300,
            height: 300 * page.height / page.width,
            format: pdfx.PdfPageImageFormat.jpeg,
            backgroundColor: '#FFFFFF',
            quality: 70,
          );

          if (mounted && pageImage != null) {
            setState(() {
              _pageCache[pageNum] = pageImage.bytes;
            });
          }

          await page.close();
        } catch (e) {
          debugPrint('❌ [ReorderPdfPage] Error loading page $pageNum: $e');
        }
      }

      await doc.close();
    } catch (e) {
      debugPrint('❌ [ReorderPdfPage] Error loading thumbnails: $e');
    }
  }

  void _toggleRemove(int pageNum) {
    setState(() {
      if (_removedPages.contains(pageNum)) {
        _removedPages.remove(pageNum);
      } else {
        _removedPages.add(pageNum);
      }
    });
  }

  void _rotatePage(int pageNum) {
    setState(() {
      final currentRotation = _rotations[pageNum] ?? 0.0;
      _rotations[pageNum] = (currentRotation + 90) % 360;
    });
  }

  Future<void> _reorderPdf(SelectionProvider selection) async {
    final files = selection.files;
    if (files.isEmpty) {
      _showError('No file selected');
      return;
    }

    final file = files.first;
    final t = AppLocalizations.of(context);

    // Check if any changes were made
    final hasReordered = _pageOrder.asMap().entries.any(
      (entry) => entry.key + 1 != entry.value,
    );
    final hasRotations = _rotations.values.any((r) => r % 360 != 0);
    final hasRemovals = _removedPages.isNotEmpty;

    // If no changes, just navigate back to home
    if (!hasReordered && !hasRotations && !hasRemovals) {
      debugPrint('ℹ️ [ReorderPdfPage] No changes made, navigating to home');
      if (mounted) {
        context.goNamed(AppRouteName.home);
      }
      return;
    }

    setState(() => _isProcessing = true);

    final progress = ValueNotifier<double>(0.0);
    final stage = ValueNotifier<String>('Starting…');
    Timer? creepTimer;

    try {
      _progressDialog.show(
        context: context,
        title: t.t('reorder_pdf_title'),
        progress: progress,
        stage: stage,
      );

      creepTimer = Timer.periodic(const Duration(milliseconds: 140), (_) {
        if (!mounted) return;
        if (progress.value < 0.98) {
          progress.value = (progress.value + 0.003).clamp(0.0, 0.98).toDouble();
        }
      });

      // Convert rotation map from degrees to page numbers with rotation
      final Map<int, double> rotationMap = {};
      for (var entry in _rotations.entries) {
        if (entry.value % 360 != 0) {
          rotationMap[entry.key] = entry.value;
        }
      }

      final destinationPath = _selectedDestinationFolder != null
          ? p.join(
              _selectedDestinationFolder!.path,
              '${p.basenameWithoutExtension(file.name)}_reordered.pdf',
            )
          : null;

      // Call manipulation service
      final result = await PdfManipulationService.manipulatePdf(
        pdfPath: file.path,
        reorderPages: hasReordered ? _pageOrder : null,
        pagesToRotate: rotationMap.isEmpty ? null : rotationMap,
        pagesToRemove: _removedPages.isEmpty ? null : _removedPages.toList(),
        destinationPath: destinationPath,
        onProgress: (p01, s) {
          if (!mounted) return;
          stage.value = s;
          if (p01 > progress.value) progress.value = p01.clamp(0.0, 1.0);
        },
      );

      if (mounted) {
        progress.value = 1.0;
        stage.value = 'Done';
        _progressDialog.dismiss(context);
      }

      setState(() => _isProcessing = false);

      result.fold(
        (error) {
          debugPrint('❌ [ReorderPdfPage] Error: $error');
          _showError(error);
        },
        (outputPath) async {
          debugPrint('✅ [ReorderPdfPage] Success: $outputPath');

          // Add to recent files
          final fileInfo = FileInfo(
            name: file.name,
            path: outputPath,
            extension: 'pdf',
            size: await File(outputPath).length(),
            lastModified: DateTime.now(),
            mimeType: 'application/pdf',
          );

          await RecentFilesService.addRecentFile(fileInfo);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(t.t('reorder_pdf_success')),
                duration: const Duration(seconds: 3),
              ),
            );

            // Trigger home page refresh
            RecentFilesSection.refreshNotifier.value++;

            // Navigate back to home
            context.goNamed(AppRouteName.home);
          }
        },
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      debugPrint('❌ [ReorderPdfPage] Exception: $e');
      _showError('Unexpected error: ${e.toString()}');
    } finally {
      creepTimer?.cancel();
      progress.dispose();
      stage.dispose();
      if (mounted) {
        _progressDialog.dismiss(context);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _previewPage(
    int pageNum,
    String pdfPath, {
    double rotationDegrees = 0.0,
  }) async {
    // Open a full-screen preview dialog for the page
    try {
      final doc = await pdfx.PdfDocument.openFile(pdfPath);
      final page = await doc.getPage(pageNum);
      final pageWidth = page.width;
      final pageHeight = page.height;
      final pageImage = await page.render(
        width: pageWidth * 2,
        height: pageHeight * 2,
        format: pdfx.PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      await page.close();
      await doc.close();

      if (!mounted || pageImage == null) return;

      final quarterTurns =
          (((rotationDegrees / 90).round() % 4) + 4) % 4; // 0..3
      final rotatedAspectRatio = (quarterTurns % 2 == 0)
          ? (pageWidth / pageHeight)
          : (pageHeight / pageWidth);

      showDialog(
        context: context,
        builder: (context) {
          final screenSize = MediaQuery.sizeOf(context);
          final maxBodyHeight = screenSize.height * 0.78;
          final maxBodyWidth = screenSize.width - 32;

          // Choose the body size that fits within screen while respecting aspect ratio.
          var bodyWidth = maxBodyWidth;
          var bodyHeight = bodyWidth / rotatedAspectRatio;
          if (bodyHeight > maxBodyHeight) {
            bodyHeight = maxBodyHeight;
            bodyWidth = bodyHeight * rotatedAspectRatio;
          }

          final image = Image.memory(pageImage.bytes, fit: BoxFit.contain);
          final rotated = quarterTurns == 0
              ? image
              : RotatedBox(quarterTurns: quarterTurns, child: image);

          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: screenSize.height * 0.85,
              child: Column(
                children: [
                  AppBar(
                    title: Text('Page $pageNum Preview'),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: bodyWidth,
                        height: bodyHeight,
                        child: InteractiveViewer(child: rotated),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('❌ [ReorderPdfPage] Preview error: $e');
      _showError('Failed to preview page');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Consumer<SelectionProvider>(
      builder: (context, selection, _) {
        final files = selection.files;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          bottomNavigationBar: files.isNotEmpty && !_isLoading
              ? Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _isProcessing
                            ? null
                            : () => _reorderPdf(selection),
                        child: _isProcessing
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Processing...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                t.t('reorder_pdf_button'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                )
              : null,
          body: files.isEmpty
              ? Center(
                  child: Padding(
                    padding: screenPadding,
                    child: Text(
                      t.t('reorder_pdf_no_file'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                )
              : _isLoading
              ? const Center(
                  child: Padding(
                    padding: screenPadding,
                    child: CircularProgressIndicator(),
                  ),
                )
              : Column(
                  children: [
                    // Header section (non-scrollable)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            t.t('reorder_pdf_title'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          Text(
                            t.t('reorder_pdf_description'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Status Widget
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${_removedPages.length} page${_removedPages.length != 1 ? 's' : ''} removed • ${_rotations.values.where((r) => r % 360 != 0).length} page${_rotations.values.where((r) => r % 360 != 0).length != 1 ? 's' : ''} rotated',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Reorderable Grid (scrollable with auto-scroll on drag)
                    Expanded(
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ReorderableGridView.builder(
                              padding: EdgeInsets.only(
                                bottom:
                                    16 +
                                    MediaQuery.of(context).padding.bottom +
                                    (files.isNotEmpty && !_isLoading
                                        ? kBottomNavigationBarHeight
                                        : 0),
                              ),
                              restrictDragScope: true,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.65,
                                  ),
                              itemCount: _pageOrder.length,
                              onReorder: _isProcessing
                                  ? (oldIndex, newIndex) {}
                                  : (oldIndex, newIndex) {
                                      setState(() {
                                        final moved = _pageOrder.removeAt(
                                          oldIndex,
                                        );
                                        _pageOrder.insert(newIndex, moved);
                                      });
                                    },
                              dragWidgetBuilder: (index, child) {
                                return Material(
                                  color: Colors.transparent,
                                  elevation: 8,
                                  borderRadius: BorderRadius.circular(12),
                                  clipBehavior: Clip.hardEdge,
                                  child: Opacity(opacity: 0.85, child: child),
                                );
                              },
                              itemBuilder: (context, index) {
                                final pageNum = _pageOrder[index];
                                final rotation = _rotations[pageNum] ?? 0.0;
                                final isRemoved = _removedPages.contains(
                                  pageNum,
                                );

                                return PdfPageThumbnail(
                                  key: ValueKey(pageNum),
                                  pageNum: pageNum,
                                  isSelected: !isRemoved,
                                  thumbnailBytes: _pageCache[pageNum],
                                  rotation: rotation,
                                  onRotate: _isProcessing
                                      ? null
                                      : () => _rotatePage(pageNum),
                                  onRemove: _isProcessing
                                      ? null
                                      : () => _toggleRemove(pageNum),
                                  onTap: _isProcessing
                                      ? null
                                      : () => _previewPage(
                                          pageNum,
                                          files.first.path,
                                          rotationDegrees: rotation,
                                        ),
                                  isRemoved: isRemoved,
                                  showRotateButton: true,
                                  showRemoveButton: true,
                                  showSelectButton: false,
                                );
                              },
                            ),
                          ),
                          // Semi-transparent overlay when processing
                          if (_isProcessing)
                            Positioned.fill(
                              child: Container(
                                color: Colors.black.withOpacity(0.3),
                                child: Center(
                                  child: Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  theme.colorScheme.primary,
                                                ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Reordering PDF...',
                                            style: theme.textTheme.bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
