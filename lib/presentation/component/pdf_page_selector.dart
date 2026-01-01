// lib/presentation/component/pdf_page_selector.dart

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf_kit/presentation/component/pdf_page_thumbnail.dart';

/// Simplified PDF page selector for selecting pages (used in pdf_to_image)
/// For reordering functionality, use the custom widgets in reorder_pdf_page.dart
class PdfPageSelector extends StatefulWidget {
  final File pdfFile;
  final Set<int> initialSelectedPages;
  final Function(Set<int> selectedPages) onSelectionChanged;

  const PdfPageSelector({
    super.key,
    required this.pdfFile,
    required this.initialSelectedPages,
    required this.onSelectionChanged,
  });

  @override
  State<PdfPageSelector> createState() => _PdfPageSelectorState();
}

class _PdfPageSelectorState extends State<PdfPageSelector> {
  late final TextEditingController _selectCtrl;
  late Set<int> _selectedPages;
  String? _selectError;
  bool _isLoading = true;
  int _totalPages = 0;
  final Map<int, Uint8List?> _pageCache = {};

  int _thumbnailLoadId = 0;

  @override
  void initState() {
    super.initState();
    _selectCtrl = TextEditingController();
    _selectedPages = Set.from(widget.initialSelectedPages);
    _loadPdf();
  }

  @override
  void dispose() {
    _selectCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    setState(() => _isLoading = true);
    try {
      final doc = await pdfx.PdfDocument.openFile(widget.pdfFile.path);
      _totalPages = doc.pagesCount;

      // If no pages were initially selected, select all by default
      if (_selectedPages.isEmpty) {
        _selectedPages = Set.from(List.generate(_totalPages, (i) => i + 1));
      }

      await doc.close();
      setState(() => _isLoading = false);

      // Notify parent of initial state
      widget.onSelectionChanged(_selectedPages);

      // Start loading page thumbnails
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadPageThumbnails();
      });
    } catch (e) {
      debugPrint('Error loading PDF: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPageThumbnails() async {
    final loadId = ++_thumbnailLoadId;
    try {
      final doc = await pdfx.PdfDocument.openFile(widget.pdfFile.path);

      for (int pageNum = 1; pageNum <= _totalPages; pageNum++) {
        if (!mounted || loadId != _thumbnailLoadId) break;
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
          debugPrint('Error loading page $pageNum: $e');
        }

        // Yield to UI so scrolling/interaction stays smooth.
        await Future<void>.delayed(Duration.zero);
      }

      await doc.close();
    } catch (e) {
      debugPrint('Error loading thumbnails: $e');
    }
  }

  void _notifyParent() {
    widget.onSelectionChanged(_selectedPages);
  }

  void _parseSelectionRange(String input) {
    if (input.trim().isEmpty) {
      setState(() {
        _selectError = 'At least one page must be selected';
      });
      return;
    }

    try {
      final ranges = input.split(',');
      final Set<int> selected = {};

      for (var range in ranges) {
        range = range.trim();
        if (range.isEmpty) continue;

        if (range.contains('-')) {
          final parts = range.split('-');
          if (parts.length != 2) {
            throw 'Invalid range format. Use format like 1-5';
          }

          final start = int.tryParse(parts[0].trim());
          final end = int.tryParse(parts[1].trim());

          if (start == null || end == null) {
            throw 'Please enter valid page numbers';
          }

          if (start < 1 || end > _totalPages) {
            throw 'Pages must be between 1 and $_totalPages';
          }

          if (start > end) {
            throw 'Start page must be less than or equal to end page';
          }

          for (int i = start; i <= end; i++) {
            selected.add(i);
          }
        } else {
          final page = int.tryParse(range);
          if (page == null) {
            throw 'Please enter valid page numbers';
          }

          if (page < 1 || page > _totalPages) {
            throw 'Page must be between 1 and $_totalPages';
          }
          selected.add(page);
        }
      }

      if (selected.isEmpty) {
        throw 'At least one page must be selected';
      }

      setState(() {
        _selectedPages = selected;
        _selectError = null;
      });
      _notifyParent();
    } catch (e) {
      setState(() {
        _selectError = e.toString();
      });
    }
  }

  void _updateTextFieldFromSelection() {
    if (_selectedPages.isEmpty) {
      _selectCtrl.text = '';
      return;
    }

    // Sort the selected pages
    final sortedPages = _selectedPages.toList()..sort();

    // Group consecutive pages into ranges
    final List<String> ranges = [];
    int? rangeStart;
    int? rangeEnd;

    for (int i = 0; i < sortedPages.length; i++) {
      final currentPage = sortedPages[i];

      if (rangeStart == null) {
        rangeStart = currentPage;
        rangeEnd = currentPage;
      } else if (currentPage == rangeEnd! + 1) {
        rangeEnd = currentPage;
      } else {
        // End of consecutive sequence
        if (rangeStart == rangeEnd) {
          ranges.add('$rangeStart');
        } else {
          ranges.add('$rangeStart-$rangeEnd');
        }
        rangeStart = currentPage;
        rangeEnd = currentPage;
      }
    }

    // Add the last range
    if (rangeStart != null) {
      if (rangeStart == rangeEnd) {
        ranges.add('$rangeStart');
      } else {
        ranges.add('$rangeStart-$rangeEnd');
      }
    }

    _selectCtrl.text = ranges.join(', ');
  }

  void _togglePage(int pageNum) {
    setState(() {
      if (_selectedPages.contains(pageNum)) {
        // Don't allow deselecting if it's the last selected page
        if (_selectedPages.length > 1) {
          _selectedPages.remove(pageNum);
        }
      } else {
        _selectedPages.add(pageNum);
      }
      _updateTextFieldFromSelection();
    });
    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Select pages text field (fixed header)
        TextField(
          controller: _selectCtrl,
          decoration: InputDecoration(
            hintText: 'e.g., 1-5, 8, 10-15',
            labelText: 'Select Pages',
            helperText: 'Enter page ranges to select, separated by commas',
            helperMaxLines: 2,
            errorText: _selectError,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.check_box_outlined),
            suffixIcon: _selectError != null
                ? Tooltip(
                    message: _selectError!,
                    child: Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                    ),
                  )
                : (_selectCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _selectCtrl.clear();
                            setState(() => _selectError = null);
                            _notifyParent();
                          },
                        )
                      : null),
          ),
          onChanged: _parseSelectionRange,
        ),
        const SizedBox(height: 16),

        // Selected count info (fixed header)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_selectedPages.length} of $_totalPages page${_selectedPages.length != 1 ? 's' : ''} selected',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pages grid (scrollable)
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: _totalPages,
            itemBuilder: (context, index) {
              final pageNum = index + 1;
              final isSelected = _selectedPages.contains(pageNum);

              return PdfPageThumbnail(
                key: ValueKey(pageNum),
                pageNum: pageNum,
                isSelected: isSelected,
                thumbnailBytes: _pageCache[pageNum],
                rotation: 0.0,
                onToggle: () => _togglePage(pageNum),
                showRotateButton: false,
                showRemoveButton: false,
                showSelectButton: true,
              );
            },
          ),
        ),
      ],
    );
  }
}
