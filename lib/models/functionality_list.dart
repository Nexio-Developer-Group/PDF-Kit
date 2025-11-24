import 'package:flutter/material.dart';
import 'package:pdf_kit/models/functionality_model.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/pages/home_page.dart';

List<Functionality> getActions(BuildContext context) {
  final localizations = AppLocalizations.of(context);
  final t = localizations.t;

  return [
    Functionality(
      id: 'watermark',
      label: t('action_watermark_label'),
      icon: Icons.water_drop_outlined,
      color: Colors.brown,
      onPressed: (ctx) => _toast(
        ctx,
        t(
          'action_coming_soon_toast',
        ).replaceAll('{feature}', t('action_watermark_label')),
      ),
    ),
    Functionality(
      id: 'esign',
      label: t('action_esign_label'),
      icon: Icons.edit_document, // if not available, use Icons.edit_note
      color: Colors.pink,
      onPressed: (context) async {
        // create a mapped selection provider and navigate to sign screen
        final selectionId = 'sign_${DateTime.now().microsecondsSinceEpoch}';
        // ensure SelectionManager is available and create provider in cache
        try {
          final mgr = Get.find<SelectionManager>();
          mgr.of(selectionId);
        } catch (_) {
          // if DI not initialized, still continue with navigation
        }

        final result = await context.pushNamed(
          AppRouteName.filesRootFullscreen,
          queryParameters: {
            'selectionId': selectionId,
            'actionText': t('sign_pdf_title'),
            'max': '1', // Limit to 1 file (PDF or image)
          },
        );

        // If the sign screen returned `true`, request recent files to refresh.
        if (result == true) {
          RecentFilesSection.refreshNotifier.value++;
        }
      },
    ),
    Functionality(
      id: 'split',
      label: t('action_split_label'),
      icon: Icons.content_cut,
      color: Colors.deepPurple,
      onPressed: (ctx) => _toast(
        ctx,
        t(
          'action_coming_soon_toast',
        ).replaceAll('{feature}', t('action_split_label')),
      ),
    ),

    // merge pdf
    Functionality(
      id: 'merge',
      label: t('action_merge_label'),
      icon: Icons.merge_type,
      color: Colors.indigo,
      onPressed: (context) async {
        // create a mapped selection provider and navigate to merge screen
        final selectionId = 'merge_${DateTime.now().microsecondsSinceEpoch}';
        // ensure SelectionManager is available and create provider in cache
        try {
          final mgr = Get.find<SelectionManager>();
          mgr.of(selectionId);
        } catch (_) {
          // if DI not initialized, still continue with navigation
        }

        await Future.delayed(const Duration(milliseconds: 150));

        if (!context.mounted) return;

        final result = await context.pushNamed(
          AppRouteName.filesRootFullscreen,
          queryParameters: {
            'selectionId': selectionId,
            'actionText': t('merge_pdf_title'),
          },
        );

        // If the merge screen returned `true`, request recent files to refresh.
        if (result == true) {
          RecentFilesSection.refreshNotifier.value++;
        }
      },
    ),

    // protect pdf
    Functionality(
      id: 'protect',
      label: t('action_protect_label'),
      icon: Icons.lock_outline,
      color: Colors.green,
      onPressed: (context) async {
        // create a mapped selection provider and navigate to file selection
        final selectionId = 'protect_${DateTime.now().microsecondsSinceEpoch}';
        // ensure SelectionManager is available and create provider in cache
        try {
          final mgr = Get.find<SelectionManager>();
          mgr.of(selectionId);
        } catch (_) {
          // if DI not initialized, still continue with navigation
        }

        final result = await context.pushNamed(
          AppRouteName.filesRootFullscreen,
          queryParameters: {
            'selectionId': selectionId,
            'actionText': t('protect_pdf_title'),
            'max': '1', // Limit to 1 PDF file
          },
        );

        // If the protect screen returned `true`, request recent files to refresh.
        if (result == true) {
          RecentFilesSection.refreshNotifier.value++;
        }
      },
    ),

    // unlock pdf
    Functionality(
      id: 'unlock',
      label: t('action_unlock_label'),
      icon: Icons.lock_open,
      color: Colors.teal,
      onPressed: (context) async {
        // create a mapped selection provider and navigate to file selection
        final selectionId = 'unlock_${DateTime.now().microsecondsSinceEpoch}';
        // ensure SelectionManager is available and create provider in cache
        try {
          final mgr = Get.find<SelectionManager>();
          mgr.of(selectionId);
        } catch (_) {
          // if DI not initialized, still continue with navigation
        }

        final result = await context.pushNamed(
          AppRouteName.filesRootFullscreen,
          queryParameters: {
            'selectionId': selectionId,
            'actionText': t('unlock_pdf_title'),
            'max': '1', // Limit to 1 PDF file
          },
        );

        // If the unlock screen returned `true`, request recent files to refresh.
        if (result == true) {
          RecentFilesSection.refreshNotifier.value++;
        }
      },
    ),

    // compress pdf
    Functionality(
      id: 'compress',
      label: t('action_compress_label'),
      icon: Icons.data_saver_on, // "compress" substitute
      color: Colors.orange,
      onPressed: (context) async {
        final selectionId = 'compress_${DateTime.now().microsecondsSinceEpoch}';
        try {
          final mgr = Get.find<SelectionManager>();
          mgr.of(selectionId);
        } catch (_) {}

        final result = await context.pushNamed(
          AppRouteName.filesRootFullscreen,
          queryParameters: {
            'selectionId': selectionId,
            'actionText': t('compress_pdf_button'),
            'max': '1', // only one file for compression
          },
        );

        if (result == true) {
          RecentFilesSection.refreshNotifier.value++;
        }
      },
    ),
    Functionality(
      id: 'all',
      label: t('action_all_tools_label'),
      icon: Icons.grid_view_rounded,
      color: Colors.blueGrey,
      onPressed: (ctx) => _toast(
        ctx,
        t(
          'action_coming_soon_toast',
        ).replaceAll('{feature}', t('action_all_tools_label')),
      ),
    ),
  ];
}

void _toast(BuildContext c, String msg) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg)));
