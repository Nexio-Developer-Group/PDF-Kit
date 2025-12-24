import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';
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
  PdfControllerPinch? _pdfController;
  bool _loading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 0;
  String? _currentPath;
  bool _isPdf = false;
  bool _isImage = false;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.path;
    _detectFileType();

    debugPrint(
      '[FileViewer] initState: isPdf=$_isPdf, isImage=$_isImage, path=$_currentPath',
    );

    if (_isPdf) {
      _loadPdf();
    } else if (_isImage) {
      // For images, validate file exists
      if (_currentPath != null && File(_currentPath!).existsSync()) {
        setState(() => _loading = false);
        debugPrint('[FileViewer] Image file validated, ready to display');
      } else {
        setState(() {
          _error = 'Image file does not exist';
          _loading = false;
        });
        debugPrint('[FileViewer] Image file does not exist: $_currentPath');
      }
    } else {
      // Unsupported file type
      setState(() {
        _error = 'Unsupported file type';
        _loading = false;
      });
      debugPrint('[FileViewer] Unsupported file type for: $_currentPath');
    }
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
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

  Future<void> _loadPdf({String? password}) async {
    debugPrint('[FileViewer] ========== _loadPdf called ==========');
    debugPrint('[FileViewer] Path: $_currentPath');
    debugPrint(
      '[FileViewer] Password provided: ${password != null ? "YES (length: ${password.length})" : "NO"}',
    );

    final path = _currentPath;
    if (path == null || path.isEmpty) {
      setState(() {
        _error = 'No file path provided';
        _loading = false;
      });
      return;
    }

    final file = File(path);
    if (!file.existsSync()) {
      setState(() {
        _error = 'File does not exist';
        _loading = false;
      });
      return;
    }

    debugPrint('[FileViewer] File exists, attempting to open PDF...');
    try {
      // Create controller with Future - PdfControllerPinch expects Future<PdfDocument>
      final controller = PdfControllerPinch(
        document: PdfDocument.openFile(path, password: password),
      );

      // Wait for document to load to get page count
      final document = await controller.document;
      debugPrint('[FileViewer] ✅ PDF opened successfully!');
      debugPrint('[FileViewer] Total pages: ${document.pagesCount}');

      setState(() {
        _pdfController = controller;
        _totalPages = document.pagesCount;
        _currentPage = 1;
        _loading = false;
        _error = null;
      });
    } catch (e, stackTrace) {
      debugPrint('[FileViewer] ❌ Error opening PDF!');
      debugPrint('[FileViewer] Error type: ${e.runtimeType}');
      debugPrint('[FileViewer] Error message: $e');
      debugPrint('[FileViewer] Stack trace: $stackTrace');

      // Check if it's a password-related error
      final errorMessage = e.toString().toLowerCase();
      final isPdfRendererException = errorMessage.contains(
        'pdfrendererexception',
      );
      final isUnknownError = errorMessage.contains('unknown error');
      final hasPasswordKeywords =
          errorMessage.contains('password') ||
          errorMessage.contains('encrypted') ||
          errorMessage.contains('protected');

      debugPrint('[FileViewer] Error analysis:');
      debugPrint(
        '[FileViewer]   - isPdfRendererException: $isPdfRendererException',
      );
      debugPrint('[FileViewer]   - isUnknownError: $isUnknownError');
      debugPrint('[FileViewer]   - hasPasswordKeywords: $hasPasswordKeywords');
      debugPrint(
        '[FileViewer]   - Will treat as password error: ${(isPdfRendererException && isUnknownError) || hasPasswordKeywords}',
      );

      // PdfRendererException with "Unknown error" is often a password issue
      // Also check for explicit password keywords
      if ((isPdfRendererException && isUnknownError) || hasPasswordKeywords) {
        // Password required or incorrect
        if (password == null) {
          // First attempt - ask for password
          // Don't set loading=false, keep showing loading while dialog is up
          _showPasswordDialog();
        } else {
          debugPrint(
            '[FileViewer] 🔐 Password was provided but still failed - incorrect password',
          );
          // Incorrect password - show error and ask again
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Incorrect password. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          // Show dialog again
          _showPasswordDialog();
        }
      } else {
        debugPrint(
          '[FileViewer] ⚠️  Not a password error - showing error message',
        );
        // Other errors
        setState(() {
          _error = 'Failed to load PDF: $e';
          _loading = false;
        });
      }
    }
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
                debugPrint(
                  '[FileViewer] 🔑 Password submitted (Enter key): length=${pwd.length}',
                );
                Navigator.of(context).pop();
                if (pwd.isNotEmpty) {
                  setState(() => _loading = true);
                  _loadPdf(password: pwd);
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
              debugPrint(
                '[FileViewer] 🔑 Password submitted (Open button): length=${pwd.length}',
              );
              Navigator.of(context).pop();
              if (pwd.isNotEmpty) {
                setState(() => _loading = true);
                _loadPdf(password: pwd);
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

          // Reload PDF with new path
          setState(() {
            _currentPath = newPath;
            _detectFileType();
            if (_isPdf) {
              _loading = true;
              _pdfController?.dispose();
              _pdfController = null;
            }
          });
          if (_isPdf) {
            _loadPdf();
          }
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
        scaffoldBackgroundColor: Colors.black87,
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
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
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
                  // PDF Viewer with zoom and pan
                  if (_isPdf && _pdfController != null)
                    PdfViewPinch(
                      controller: _pdfController!,
                      padding: 10,
                      minScale:
                          1.0, // Limit zoom out to fit-to-screen (no cropping)
                      maxScale: 4.0, // Allow zooming in to 400%
                      onPageChanged: (page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      onDocumentLoaded: (document) {
                        debugPrint(
                          '[FileViewer] Document loaded: ${document.pagesCount} pages',
                        );
                      },
                    )
                  // Image Viewer with zoom and pan
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
                    // Fallback - should not happen if error handling is correct
                    const SizedBox.shrink(),
                  // Floating page indicator (PDFs only)
                  if (_isPdf && _totalPages > 0)
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
                          'Page $_currentPage / $_totalPages',
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
