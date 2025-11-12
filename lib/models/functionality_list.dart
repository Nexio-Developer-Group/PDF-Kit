import 'package:flutter/material.dart';
import 'package:pdf_kit/models/functionality_model.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/dependency_injection.dart';

final List<Functionality> actions = [
  Functionality(
    id: 'watermark',
    label: 'Watermark',
    icon: Icons.water_drop_outlined,
    color: Colors.brown,
    onPressed: (context) => _toast(context, 'Watermark'),
  ),
  Functionality(
    id: 'esign',
    label: 'eSign PDF',
    icon: Icons.edit_document, // if not available, use Icons.edit_note
    color: Colors.pink,
    onPressed: (context) => _toast(context, 'eSign PDF'),
  ),
  Functionality(
    id: 'split',
    label: 'Split PDF',
    icon: Icons.content_cut,
    color: Colors.deepPurple,
    onPressed: (context) => _toast(context, 'Split PDF'),
  ),
  Functionality(
    id: 'merge',
    label: 'Merge PDF',
    icon: Icons.merge_type,
    color: Colors.indigo,
    onPressed: (context) {
      // create a mapped selection provider and navigate to merge screen
      final selectionId = 'merge_${DateTime.now().microsecondsSinceEpoch}';
      // ensure SelectionManager is available and create provider in cache
      try {
        final mgr = Get.find<SelectionManager>();
        mgr.of(selectionId);
      } catch (_) {
        // if DI not initialized, still continue with navigation
      }

      context.pushNamed(
        AppRouteName.mergePdf,
        queryParameters: {'selectionId': selectionId},
      );
    },
  ),
  Functionality(
    id: 'protect',
    label: 'Protect PDF',
    icon: Icons.lock_outline,
    color: Colors.green,
    onPressed: (context) => _toast(context, 'Protect PDF'),
  ),
  Functionality(
    id: 'compress',
    label: 'Compress PDF',
    icon: Icons.data_saver_on, // "compress" substitute
    color: Colors.orange,
    onPressed: (context) => _toast(context, 'Compress PDF'),
  ),
  Functionality(
    id: 'all',
    label: 'All Tools',
    icon: Icons.grid_view_rounded,
    color: Colors.blueGrey,
    onPressed: (context) => _toast(context, 'All Tools'),
  ),
];

void _toast(BuildContext c, String msg) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg)));
