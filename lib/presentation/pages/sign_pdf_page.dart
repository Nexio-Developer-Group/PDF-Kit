import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/service/signature_service.dart';
import 'package:pdf_kit/presentation/sheets/signature_pick_sheet.dart';

class SignPdfPage extends StatefulWidget {
  final String? selectionId;
  const SignPdfPage({super.key, this.selectionId});

  @override
  State<SignPdfPage> createState() => _SignPdfPageState();
}

class _SignPdfPageState extends State<SignPdfPage> {
  bool _loading = true;
  bool _saving = false;
  FileInfo? _file;
  Uint8List? _fileBytes;
  bool _isPdf = false;

  // PDF-specific
  int _currentPage = 1;
  int _totalPages = 1;
  Uint8List? _currentPageImage;

  // Signature state
  Uint8List? _signatureBytes;
  double _sigLeftFrac = 0.15;
  double _sigTopFrac = 0.70;
  double _sigWidthFrac = 0.35;

  double _lastPageWidth = 1;
  double _lastPageHeight = 1;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    final selection = Provider.of<SelectionProvider>(context, listen: false);
    if (selection.files.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    final file = selection.files.first;
    setState(() => _file = file);

    try {
      final bytes = await File(file.path).readAsBytes();
      final isPdf = file.mimeType?.contains('pdf') ?? file.extension == 'pdf';

      setState(() {
        _fileBytes = bytes;
        _isPdf = isPdf;
      });

      if (isPdf) {
        await _loadPdfInfo();
      } else {
        setState(() {
          _currentPageImage = bytes;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading file: $e')));
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadPdfInfo() async {
    if (_fileBytes == null) return;

    final pageCountResult = await SignatureService.getPdfPageCount(_fileBytes!);
    pageCountResult.fold(
      (error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
        setState(() => _loading = false);
      },
      (count) async {
        setState(() => _totalPages = count);
        await _loadPage(_currentPage);
      },
    );
  }

  Future<void> _loadPage(int pageNumber) async {
    if (_fileBytes == null) return;

    setState(() => _loading = true);

    final pageResult = await SignatureService.loadPdfPageAsImage(
      _fileBytes!,
      pageNumber,
    );

    if (mounted) {
      pageResult.fold(
        (error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
          setState(() => _loading = false);
        },
        (pageImage) {
          setState(() {
            _currentPageImage = pageImage.bytes;
            _currentPage = pageNumber;
            _loading = false;
          });
        },
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _loadPage(_currentPage + 1);
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _loadPage(_currentPage - 1);
    }
  }

  Future<void> _handleAddSignature() async {
    final signature = await showSignaturePickSheet(context: context);
    if (signature != null && mounted) {
      setState(() => _signatureBytes = signature);
    }
  }

  void _handleChangeSignature() {
    _handleAddSignature();
  }

  void _handleRemoveSignature() {
    setState(() => _signatureBytes = null);
  }

  double _baseScale = 1.0;

  void _updateFromScale(ScaleUpdateDetails details) {
    setState(() {
      // Handle dragging (position change)
      if (details.scale == 1.0) {
        _sigLeftFrac += details.focalPointDelta.dx / _lastPageWidth;
        _sigTopFrac += details.focalPointDelta.dy / _lastPageHeight;

        _sigLeftFrac = _sigLeftFrac.clamp(0.0, 1.0 - _sigWidthFrac);
        _sigTopFrac = _sigTopFrac.clamp(0.0, 1.0);
      } else {
        // Handle scaling (size change)
        final newWidth = _sigWidthFrac * (details.scale / _baseScale);
        _sigWidthFrac = newWidth.clamp(0.1, 0.8);
        _baseScale = details.scale;
      }
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = 1.0;
  }

  Future<void> _handleComplete() async {
    if (_signatureBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a signature first')),
      );
      return;
    }

    if (_fileBytes == null || _file == null) return;

    setState(() => _saving = true);

    try {
      late Uint8List signedBytes;

      if (_isPdf) {
        signedBytes = await SignatureService.buildSignedPdfBytes(
          originalPdfBytes: _fileBytes!,
          pageNumber: _currentPage,
          signatureBytes: _signatureBytes!,
          sigLeftFrac: _sigLeftFrac,
          sigTopFrac: _sigTopFrac,
          sigWidthFrac: _sigWidthFrac,
        );
      } else {
        signedBytes = await SignatureService.buildSignedImageBytes(
          imageBytes: _fileBytes!,
          signatureBytes: _signatureBytes!,
          sigLeftFrac: _sigLeftFrac,
          sigTopFrac: _sigTopFrac,
          sigWidthFrac: _sigWidthFrac,
        );
      }

      final saveResult = await SignatureService.saveAndOpenSignedFile(
        bytes: signedBytes,
        originalFileName: _file!.name,
        isPdf: _isPdf,
      );

      if (!mounted) return;

      saveResult.fold(
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        (fileInfo) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Signed file saved: ${fileInfo.name}'),
              backgroundColor: Colors.green,
            ),
          );

          final selection = Provider.of<SelectionProvider>(
            context,
            listen: false,
          );
          selection.disable();
          context.pop(true);
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
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('sign_pdf_title')),
        actions: [
          if (_signatureBytes != null && !_saving)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _handleChangeSignature,
              tooltip: 'Change Signature',
            ),
          if (_signatureBytes != null && !_saving)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _handleRemoveSignature,
              tooltip: 'Remove Signature',
            ),
        ],
      ),
      body: _loading || _currentPageImage == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // PDF Preview with page navigation
                Expanded(
                  child: GestureDetector(
                    onVerticalDragEnd: (details) {
                      if (!_isPdf) return;
                      if (details.velocity.pixelsPerSecond.dy > 0) {
                        _previousPage();
                      } else if (details.velocity.pixelsPerSecond.dy < 0) {
                        _nextPage();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          _lastPageWidth = constraints.maxWidth;
                          _lastPageHeight = constraints.maxHeight;

                          return Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Page preview
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      _currentPageImage!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),

                                // Signature overlay
                                if (_signatureBytes != null)
                                  Positioned(
                                    left: _sigLeftFrac * _lastPageWidth,
                                    top: _sigTopFrac * _lastPageHeight,
                                    child: GestureDetector(
                                      onScaleStart: _onScaleStart,
                                      onScaleUpdate: _updateFromScale,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.5),
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Image.memory(
                                          _signatureBytes!,
                                          width: _sigWidthFrac * _lastPageWidth,
                                        ),
                                      ),
                                    ),
                                  ),

                                // Navigation buttons for PDF
                                if (_isPdf && _totalPages > 1) ...[
                                  if (_currentPage > 1)
                                    Positioned(
                                      left: 8,
                                      child: IconButton.filledTonal(
                                        onPressed: _previousPage,
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new,
                                        ),
                                      ),
                                    ),
                                  if (_currentPage < _totalPages)
                                    Positioned(
                                      right: 8,
                                      child: IconButton.filledTonal(
                                        onPressed: _nextPage,
                                        icon: const Icon(
                                          Icons.arrow_forward_ios,
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // Page indicator
                if (_isPdf)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Page $_currentPage of $_totalPages',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),

                // Action buttons
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        if (_signatureBytes == null)
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _saving ? null : _handleAddSignature,
                              icon: const Icon(Icons.edit),
                              label: const Text('Add Signature'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: FilledButton(
                              onPressed: _saving ? null : _handleComplete,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Complete'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
