import 'package:flutter/material.dart';
import 'package:pdf_kit/models/functionality_model.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/pages/home_page.dart';

List<Functionality> getActions(BuildContext context) {
  final localizations = AppLocalizations.of(context);
  final t = localizations.t;

  return [
    // Merge PDF
    Functionality(
      id: 'merge',
      label: t('action_merge_label'),
      icon: Icons.merge_type,
      color: Colors.indigo,
      onPressed: (context) async {
        final selectionId = 'merge_${DateTime.now().microsecondsSinceEpoch}';
        debugPrint(
          '🔵 [Functionality] MERGE clicked - selectionId: $selectionId',
        );
        try {
          final mgr = Get.find<SelectionManager>();
          final provider = mgr.of(selectionId);
          provider.setFileType('all');
        } catch (_) {}

        await Future.delayed(const Duration(milliseconds: 150));

        if (!context.mounted) return;

        debugPrint('🔵 [Functionality] MERGE navigating with op="merge"');
        final result = await context.pushNamed(
          AppRouteName.filesRootFullscreen,
          queryParameters: {
            'selectionId': selectionId,
            'actionText': t('merge_pdf_title'),
            'min': '2', // Merge requires at least 2 files
            'op': 'merge',
            'allowed': 'unprotected',
            'fileType': 'all',
          },
        );

        if (result == true) {
          RecentFilesSection.refreshNotifier.value++;
        }
      },
    ),

    // Images to PDF
    Functionality(
      id: 'images_to_pdf',
      label: t('action_images_to_pdf_label'),
      icon: Icons.picture_as_pdf,
      color: Colors.blue,
      onPressed: (context) async {
        final selectionId =
            'images_to_pdf_${DateTime.now().microsecondsSinceEpoch}';
        try {
          final mgr = Get.find<SelectionManager>();
          final provider = mgr.of(selectionId);
          provider.setFileType('images');
        } catch (_) {}

        final result = await context.pushNamed(
          AppRouteName.filesRootFullscreen,
          queryParameters: {
            'selectionId': selectionId,
            'actionText': t('images_to_pdf_title'),
            'min': '2', // Require at least 2 images
            'op': 'images_to_pdf',
            'allowed': 'images', // Only allow image files
            'fileType': 'images',
          },
        );

        if (result == true) {
          RecentFilesSection.refreshNotifier.value++;
        }
      },
    ),

    // Split PDF
    Functionality(
      id: 'split',
      label: t('action_split_label'),
      icon: Icons.content_cut,
      color: Colors.deepPurple,
      onPressed: (context) async {
        final selectionId = 'split_${DateTime.now().microsecondsSinceEpoch}';
        debugPrint(
          '✂️ [Functionality] SPLIT clicked - selectionId: $selectionId',
        );
        try {
          final mgr = Get.find<SelectionManager>();
          final provider = mgr.of(selectionId);
          provider.setFileType('pdf');
        } catch (_) {}

        debugPrint('✂️ [Functionality] SPLIT navigating with op="split"');
        final result = await context.pushNamed(
          AppRouteName.filesRootFullscreen,
          queryParameters: {
            'selectionId': selectionId,
            'actionText': t('split_pdf_title'),
            'max': '1', // Only one PDF at a time
            'op': 'split',
            'min': '1',
            'allowed': 'unprotected',
            'fileType': 'pdf',
          },
        );

        if (result == true && context.mounted) {
          // Navigate to split PDF page
          await context.pushNamed(
            AppRouteName.splitPdf,
            queryParameters: {'selectionId': selectionId},
          );
          RecentFilesSection.refreshNotifier.value++;
        }
      },
    ),

    // Protect PDF
    Functionality(
      id: 'protect',
      label: t('action_protect_label'),
      icon: Icons.lock_outline,
      color: Colors.green,
      onPressed: (context) async {
        final selectionId = 'protect_${DateTime.now().microsecondsSinceEpoch}';
        debugPrint(
          '🔒 [Functionality] PROTECT clicked - selectionId: $selectionId',
        );
        try {
          final mgr = Get.find<SelectionManager>();
          final provider = mgr.of(selectionId);
          provider.setFileType('pdf');
        } catch (_) {}

        debugPrint('🔒 [Functionality] PROTECT navigating with op="protect"');
        final result = await context.pushNamed(
          AppRouteName.filesRootFullscreen,
          queryParameters: {
            'selectionId': selectionId,
            'actionText': t('protect_pdf_title'),
            'max': '1',
            'op': 'protect',
            'min': '1',
            'allowed': 'unprotected',
            'fileType': 'pdf',
          },
        );

        if (result == true) {
          RecentFilesSection.refreshNotifier.value++;
        }
      },
    ),

    // Remove Password
    Functionality(
      id: 'unlock',
      label: t('action_unlock_label'),
      icon: Icons.lock_open,
      color: Colors.teal,
      onPressed: (context) async {
        final selectionId = 'unlock_${DateTime.now().microsecondsSinceEpoch}';
        try {
          final mgr = Get.find<SelectionManager>();
          final provider = mgr.of(selectionId);
          provider.setFileType('pdf');
        } catch (_) {}

        final result = await context.pushNamed(
          AppRouteName.filesRootFullscreen,
          queryParameters: {
            'selectionId': selectionId,
            'actionText': t('unlock_pdf_title'),
            'max': '1',
            'op': 'unlock',
            'min': '1',
            'allowed': 'protected',
            'fileType': 'pdf',
          },
        );

        if (result == true) {
          RecentFilesSection.refreshNotifier.value++;
        }
      },
    ),

    // Compress PDF
    Functionality(
      id: 'compress',
      label: t('action_compress_label'),
      icon: Icons.compress,
      color: Colors.orange,
      onPressed: (context) async {
        final selectionId = 'compress_${DateTime.now().microsecondsSinceEpoch}';
        try {
          final mgr = Get.find<SelectionManager>();
          final provider = mgr.of(selectionId);
          provider.setFileType('pdf');
        } catch (_) {}

        final result = await context.pushNamed(
          AppRouteName.filesRootFullscreen,
          queryParameters: {
            'selectionId': selectionId,
            'actionText': t('compress_pdf_button'),
            'max': '1',
            'op': 'compress',
            'min': '1',
            'allowed': 'unprotected',
            'fileType': 'pdf',
          },
        );

        if (result == true) {
          RecentFilesSection.refreshNotifier.value++;
        }
      },
    ),

    // PDF to Image
    Functionality(
      id: 'pdf_to_image',
      label: t('action_pdf_to_image_label'),
      icon: Icons.image,
      color: Colors.pink,
      onPressed: (context) async {
        final selectionId =
            'pdf_to_image_${DateTime.now().microsecondsSinceEpoch}';
        try {
          final mgr = Get.find<SelectionManager>();
          final provider = mgr.of(selectionId);
          provider.setFileType('pdf');
        } catch (_) {}

        final result = await context.pushNamed(
          AppRouteName.filesRootFullscreen,
          queryParameters: {
            'selectionId': selectionId,
            'actionText': t('pdf_to_image_title'),
            'max': '1',
            'op': 'pdf_to_image',
            'min': '1',
            'allowed': 'unprotected',
            'fileType': 'pdf',
          },
        );

        if (result == true) {
          RecentFilesSection.refreshNotifier.value++;
        }
      },
    ),

    // Reorder PDF
    Functionality(
      id: 'reorder',
      label: t('action_reorder_label'),
      icon: Icons.reorder,
      color: Colors.brown,
      onPressed: (context) async {
        final selectionId = 'reorder_${DateTime.now().microsecondsSinceEpoch}';
        debugPrint(
          '🔄 [Functionality] REORDER clicked - selectionId: $selectionId',
        );
        try {
          final mgr = Get.find<SelectionManager>();
          final provider = mgr.of(selectionId);
          provider.setFileType('pdf');
        } catch (_) {}

        debugPrint('🔄 [Functionality] REORDER navigating with op="reorder"');
        final result = await context.pushNamed(
          AppRouteName.filesRootFullscreen,
          queryParameters: {
            'selectionId': selectionId,
            'actionText': t('reorder_pdf_title'),
            'max': '1',
            'op': 'reorder',
            'min': '1',
            'allowed': 'unprotected',
            'fileType': 'pdf',
          },
        );

        if (result == true) {
          RecentFilesSection.refreshNotifier.value++;
        }
      },
    ),
  ];
}

// void _toast(BuildContext c, String msg) =>
//     ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg)));
