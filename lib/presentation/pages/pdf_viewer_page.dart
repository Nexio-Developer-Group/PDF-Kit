import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:provider/provider.dart';
import 'package:pdf_kit/presentation/sheets/pdf_options_sheet.dart';
import 'package:pdf_kit/presentation/sheets/rename_file_sheet.dart';
import 'package:pdf_kit/presentation/sheets/delete_file_sheet.dart';
import 'package:pdf_kit/providers/file_system_provider.dart';
import 'package:pdf_kit/models/file_model.dart';

/// Full-featured file viewer supporting both PDFs and images.
/// - PDFs: Native rendering with zoom/pan, password protection
/// - Images: InteractiveViewer with zoom/pan support
class FileViewerPage extends StatefulWidget {
  final String? path;

  const FileViewerPage({super.key, this.path});

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
      onRename: _handleRename,
      onDelete: _handleDelete,
      onSplit: _isPdf
          ? () {
              debugPrint('[FileViewer] Split action - not implemented');
            }
          : null,
      onProtect: _isPdf
          ? () {
              debugPrint(
                '[FileViewer] Protect/Unlock action - not implemented',
              );
            }
          : null,
      onCompress: _isPdf
          ? () {
              debugPrint('[FileViewer] Compress action - not implemented');
            }
          : null,
      onMoveToFolder: () {
        debugPrint('[FileViewer] Move to folder action - not implemented');
      },
    );
  }

  Future<void> _handleRename() async {
    if (_currentPath == null) return;

    final file = File(_currentPath!);
    final currentName = p.basenameWithoutExtension(_currentPath!);
    final extension = p.extension(_currentPath!);

    await showRenameFileSheet(
      context: context,
      initialName: currentName,
      onRename: (newName) async {
        // Create FileInfo from current path
        final stat = await file.stat();
        final fileInfo = FileInfo(
          name: p.basename(_currentPath!),
          path: _currentPath!,
          extension: extension,
          size: stat.size,
          lastModified: stat.modified,
          parentDirectory: p.dirname(_currentPath!),
          isDirectory: false,
        );

        // Add extension if not present
        final newFileName = newName.endsWith(extension)
            ? newName
            : '$newName$extension';

        // Use FileSystemProvider to rename
        await context.read<FileSystemProvider>().renameFile(
          fileInfo,
          newFileName,
        );

        // Update current path and reload
        final newPath = p.join(p.dirname(_currentPath!), newFileName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File renamed successfully')),
          );

          setState(() {
            _currentPath = newPath;
            _detectFileType();
            if (_isPdf) {
              _pdfViewerKey = UniqueKey(); // Reload PDF
            }
          });
        }
      },
    );
  }

  Future<void> _handleDelete() async {
    if (_currentPath == null) return;

    final file = File(_currentPath!);
    final fileName = p.basename(_currentPath!);

    await showDeleteFileSheet(
      context: context,
      fileName: fileName,
      onDelete: () async {
        // Create FileInfo from current path
        final stat = await file.stat();
        final fileInfo = FileInfo(
          name: fileName,
          path: _currentPath!,
          extension: p.extension(_currentPath!),
          size: stat.size,
          lastModified: stat.modified,
          parentDirectory: p.dirname(_currentPath!),
          isDirectory: false,
        );

        // Use FileSystemProvider to delete
        await context.read<FileSystemProvider>().deleteFile(fileInfo);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File deleted successfully')),
          );

          // Navigate back after deletion
          Navigator.of(context).pop();
        }
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
                              // HACK: Re-enable loading state and show password dialog
                              // But we can't show dialog in build. Schedule it.
                              Future.microtask(() {
                                if (mounted && _password == null) {
                                  _showPasswordDialog();
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
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
