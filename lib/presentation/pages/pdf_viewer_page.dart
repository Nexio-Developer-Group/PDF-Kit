import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/sheets/pdf_options_sheet.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/presentation/sheets/delete_file_sheet.dart';
import 'package:pdf_kit/presentation/sheets/rename_file_sheet.dart';
import 'package:pdf_kit/service/file_service.dart';

/// Full-featured file viewer supporting both PDFs and images.
/// - PDFs: Native rendering with zoom/pan, password protection
/// - Images: InteractiveViewer with zoom/pan support
class FileViewerPage extends StatefulWidget {
  final String? path;
  final bool showOptionsSheet;

  const FileViewerPage({super.key, this.path, this.showOptionsSheet = true});

  @override
  State<FileViewerPage> createState() => _FileViewerPageState();
}

class _FileViewerPageState extends State<FileViewerPage> {
  final Completer<PDFViewController> _pdfController =
      Completer<PDFViewController>();
  bool _loading = true;
  String? _error;
  int _currentPage = 0;
  int _totalPages = 0;
  String? _currentPath;
  bool _isPdf = false;
  bool _isImage = false;
  String? _password;
  Key _pdfViewerKey = UniqueKey(); // Key to force rebuild PDF view

  @override
  void initState() {
    super.initState();
    _currentPath = widget.path;
    _detectFileType();

    debugPrint(
      '[FileViewer] initState: isPdf=$_isPdf, isImage=$_isImage, path=$_currentPath',
    );

    if (_isPdf) {
      // PDF loading is handled by the PDFView widget itself
      _validateFile();
    } else if (_isImage) {
      _validateFile();
    } else {
      // Unsupported file type
      setState(() {
        _error = 'Unsupported file type';
        _loading = false;
      });
      debugPrint('[FileViewer] Unsupported file type for: $_currentPath');
    }
  }

  void _validateFile() {
    if (_currentPath != null && File(_currentPath!).existsSync()) {
      setState(() => _loading = false);
      debugPrint('[FileViewer] File validated, ready to display');
    } else {
      setState(() {
        _error = 'File does not exist';
        _loading = false;
      });
      debugPrint('[FileViewer] File does not exist: $_currentPath');
    }
  }

  void _detectFileType() {
    if (_currentPath == null) return;

    final extension = p.extension(_currentPath!).toLowerCase();
    _isPdf = extension == '.pdf';
    _isImage = const {
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.bmp',
      '.heic',
      '.heif',
    }.contains(extension);

    debugPrint(
      '[FileViewer] File type detected: isPdf=$_isPdf, isImage=$_isImage',
    );
  }

  void _showPasswordDialog() {
    debugPrint('[FileViewer] 📝 Showing password dialog...');
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Password Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This PDF is password protected.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Enter password',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) {
                final pwd = passwordController.text;
                Navigator.of(context).pop();
                if (pwd.isNotEmpty) {
                  setState(() {
                    _password = pwd;
                    _pdfViewerKey = UniqueKey(); // Rebuild with new password
                    _loading = true;
                    _error = null;
                  });
                } else {
                  _showPasswordDialog(); // Show again if empty
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Exit PDF viewer
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final pwd = passwordController.text;
              Navigator.of(context).pop();
              if (pwd.isNotEmpty) {
                setState(() {
                  _password = pwd;
                  _pdfViewerKey = UniqueKey(); // Rebuild with new password
                  _loading = true;
                  _error = null;
                });
              } else {
                _showPasswordDialog(); // Show again if empty
              }
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  void _showOptionsSheet() {
    if (_currentPath == null) return;
    showPdfOptionsSheet(
      context: context,
      pdfPath: _currentPath!,
      isPdf: _isPdf,
      onRename: () => unawaited(_renameCurrentFile()),
      onDelete: () => unawaited(_deleteCurrentFile()),
      onMoveToFolder: () => unawaited(_moveCurrentFileToFolder()),
      onMergePdf: () => _startOperationFromViewer(
        op: 'merge',
        actionTextKey: 'merge_pdf_title',
        allowed: 'unprotected',
        fileType: 'all',
        min: 2,
        max: null,
        preselectIfPdfOnly: true,
      ),
      onImagesToPdf: () => _startOperationFromViewer(
        op: 'images_to_pdf',
        actionTextKey: 'images_to_pdf_title',
        allowed: 'images',
        fileType: 'images',
        min: 2,
        max: null,
        preselectIfPdfOnly: false,
      ),
      onSplit: () => _startOperationFromViewer(
        op: 'split',
        actionTextKey: 'split_pdf_title',
        allowed: 'unprotected',
        fileType: 'pdf',
        min: 1,
        max: 1,
        preselectIfPdfOnly: true,
      ),
      onProtect: () => _startOperationFromViewer(
        op: 'protect',
        actionTextKey: 'protect_pdf_title',
        allowed: 'unprotected',
        fileType: 'pdf',
        min: 1,
        max: 1,
        preselectIfPdfOnly: true,
      ),
      onCompress: () => _startOperationFromViewer(
        op: 'compress',
        actionTextKey: 'compress_pdf_button',
        allowed: 'unprotected',
        fileType: 'pdf',
        min: 1,
        max: 1,
        preselectIfPdfOnly: true,
      ),
      onPdfToImage: () => _startOperationFromViewer(
        op: 'pdf_to_image',
        actionTextKey: 'pdf_to_image_title',
        allowed: 'unprotected',
        fileType: 'pdf',
        min: 1,
        max: 1,
        preselectIfPdfOnly: true,
      ),
      onReorder: () => _startOperationFromViewer(
        op: 'reorder',
        actionTextKey: 'reorder_pdf_title',
        allowed: 'unprotected',
        fileType: 'pdf',
        min: 1,
        max: 1,
        preselectIfPdfOnly: true,
      ),
    );
  }

  Future<void> _renameCurrentFile() async {
    final info = await _buildCurrentFileInfo();
    if (info == null) return;
    if (!mounted) return;

    await showRenameFileSheet(
      context: context,
      initialName: info.name,
      onRename: (newName) => unawaited(_performRename(info, newName)),
    );
  }

  Future<void> _performRename(FileInfo file, String newName) async {
    final result = await FileService.renameFile(file, newName);
    result.fold(
      (err) {
        if (!mounted) return;
        AppSnackbar.show(err.message);
      },
      (updated) {
        if (!mounted) return;
        setState(() {
          _currentPath = updated.path;
          _detectFileType();
          if (_isPdf) {
            _pdfViewerKey = UniqueKey();
          }
        });
      },
    );
  }

  Future<void> _deleteCurrentFile() async {
    final info = await _buildCurrentFileInfo();
    if (info == null) return;
    if (!mounted) return;

    await showDeleteFileSheet(
      context: context,
      fileName: info.name,
      onDelete: () => unawaited(_performDelete(info)),
    );
  }

  Future<void> _performDelete(FileInfo file) async {
    final result = await FileService.deleteFile(file);
    result.fold(
      (err) {
        if (!mounted) return;
        AppSnackbar.show(err.message);
      },
      (_) {
        if (!mounted) return;
        Navigator.of(context).pop();
      },
    );
  }

  Future<void> _moveCurrentFileToFolder() async {
    final info = await _buildCurrentFileInfo();
    if (info == null) return;
    if (!mounted) return;

    final router = GoRouter.of(context);
    final t = AppLocalizations.of(context);

    final selectedPath = await router.pushNamed(
      AppRouteName.folderPickScreen,
      extra: {
        'path': info.parentDirectory,
        'title': t.t('folder_picker_title'),
        'description': _isPdf
            ? t.t('folder_picker_description_pdfs')
            : t.t('folder_picker_description_images'),
      },
    );

    final destinationPath = selectedPath is String ? selectedPath : null;
    if (destinationPath == null || destinationPath.isEmpty) return;

    final moved = await FileService.moveFile(
      info,
      destinationPath: destinationPath,
    );
    moved.fold(
      (err) {
        if (!mounted) return;
        AppSnackbar.show(err.message);
      },
      (updated) {
        if (!mounted) return;
        setState(() {
          _currentPath = updated.path;
          _detectFileType();
          if (_isPdf) {
            _pdfViewerKey = UniqueKey();
          }
        });
      },
    );
  }

  Future<FileInfo?> _buildCurrentFileInfo() async {
    final path = _currentPath;
    if (path == null) return null;

    final f = File(path);
    if (!await f.exists()) return null;

    final stat = await f.stat();
    final ext = p.extension(path);
    final extensionNoDot = ext.startsWith('.') ? ext.substring(1) : ext;

    return FileInfo(
      name: p.basename(path),
      path: path,
      extension: extensionNoDot,
      size: stat.size,
      lastModified: stat.modified,
      parentDirectory: p.dirname(path),
      isDirectory: false,
    );
  }

  Future<void> _startOperationFromViewer({
    required String op,
    required String actionTextKey,
    required String allowed,
    required String fileType,
    required int min,
    required int? max,
    required bool preselectIfPdfOnly,
  }) async {
    final path = _currentPath;
    if (path == null) return;

    final selectionId = '${op}_${DateTime.now().microsecondsSinceEpoch}';

    // Prepare provider (same mechanism as functionality buttons).
    SelectionProvider? provider;
    try {
      provider = Get.find<SelectionManager>().of(selectionId);
    } catch (_) {
      provider = null;
    }

    if (provider != null) {
      provider.disable();
      provider.enable();
      provider.setAllowedFilter(allowed);
      provider.setFileType(fileType);
      provider.setMinSelectable(min);
      provider.setMaxSelectable(max);

      // Preselect current document when it matches the operation.
      final info = await _buildCurrentFileInfo();
      if (info != null) {
        final isPdf = p.extension(info.path).toLowerCase() == '.pdf';
        final isImage = const {
          '.jpg',
          '.jpeg',
          '.png',
          '.gif',
          '.webp',
          '.bmp',
          '.heic',
          '.heif',
        }.contains(p.extension(info.path).toLowerCase());

        final shouldPreselect = preselectIfPdfOnly ? isPdf : isImage;
        if (shouldPreselect) {
          await provider.toggle(info);
        }
      }
    }

    if (!mounted) return;

    final router = GoRouter.of(context);
    final t = AppLocalizations.of(context);

    // Push selection first, then auto-open operation page on top.
    await router.pushNamed(
      AppRouteName.filesRootFullscreen,
      queryParameters: {
        'selectionId': selectionId,
        'actionText': t.t(actionTextKey),
        'allowed': allowed,
        'fileType': fileType,
        'min': min.toString(),
        if (max != null) 'max': max.toString(),
        'op': op,
        'auto': '1',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Force dark theme for this page
    return Theme(
      data: ThemeData.dark().copyWith(
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            _currentPath != null ? p.basename(_currentPath!) : 'File Viewer',
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            if (widget.showOptionsSheet)
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: _showOptionsSheet,
              ),
          ],
        ),
        body: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Stack(
                children: [
                  // PDF Viewer
                  if (_isPdf && _currentPath != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: PDFView(
                        key: _pdfViewerKey,
                        filePath: _currentPath,
                        password: _password,
                        enableSwipe: true,
                        swipeHorizontal: false, // Vertical scrolling
                        autoSpacing: false, // Gap between pages
                        pageFling:
                            false, // important: no ViewPager-like one-page fling
                        pageSnap: false, // keep off (Android-only)
                        defaultPage: _currentPage,
                        fitPolicy: FitPolicy.BOTH, // Fit each page to screen
                        fitEachPage:
                            true, // Ensure each page is fit independently
                        backgroundColor: Colors.black, // True black background
                        preventLinkNavigation: false,
                        onRender: (pages) {
                          setState(() {
                            _totalPages = pages ?? 0;
                            _loading = false;
                            _error = null;
                          });
                          debugPrint(
                            '[FileViewer] Document loaded: $pages pages',
                          );
                        },
                        onError: (error) {
                          debugPrint(
                            '[FileViewer] ❌ Error opening PDF: $error',
                          );
                          setState(() {
                            // Attempt to detect password error purely by the error string or behavior
                            // flutter_pdfview is not always consistent with error codes
                            // But usually if password is provided and wrong, or not provided and needed...

                            // If it's a password issue, try to show dialog
                            if (error.toString().toLowerCase().contains(
                                  'password',
                                ) ||
                                error.toString().toLowerCase().contains(
                                  'encrypted',
                                ) ||
                                // Some native errors might be generic
                                (_password == null &&
                                    error.toString().isNotEmpty)) {
                              // But we can't show dialog in build. Schedule it.
                              Future.microtask(() {
                                if (!context.mounted) return;
                                if (_password == null) {
                                  _showPasswordDialog();
                                } else {
                                  AppSnackbar.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Incorrect password or file error.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  // Show dialog again
                                  _showPasswordDialog();
                                }
                              });
                            } else {
                              _error = error.toString();
                              _loading = false;
                            }
                          });
                        },
                        onPageError: (page, error) {
                          debugPrint('[FileViewer] Page $page error: $error');
                        },
                        onViewCreated: (PDFViewController pdfViewController) {
                          if (!_pdfController.isCompleted) {
                            _pdfController.complete(pdfViewController);
                          }
                        },
                        onPageChanged: (int? page, int? total) {
                          setState(() {
                            _currentPage = page ?? 0;
                          });
                        },
                      ),
                    )
                  // Image Viewer
                  else if (_isImage && _currentPath != null)
                    InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(
                        child: Image.file(
                          File(_currentPath!),
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Loading Indicator
                  if (_loading)
                    const Center(child: CircularProgressIndicator()),

                  // Floating page indicator (PDFs only)
                  if (_isPdf && _totalPages > 0 && !_loading)
                    Positioned(
                      bottom: 24,
                      right: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Page ${_currentPage + 1} / $_totalPages',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
