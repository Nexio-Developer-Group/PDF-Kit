import 'package:flutter/material.dart';
import 'package:pdf_kit/models/functionality_model.dart';

final List<Functionality> actions = [
  Functionality(
    id: 'scan',
    label: 'Scan Code',
    icon: Icons.document_scanner_outlined,
    color: Colors.amber,
    onPressed: (context) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Scan Code')));
    },
  ),
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
    onPressed: (context) => _toast(context, 'Merge PDF'),
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
