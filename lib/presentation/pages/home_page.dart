import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/models/functionality_list.dart';
import 'package:pdf_kit/models/functionality_model.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/function_button.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/service/recent_file_service.dart';

/// HOME TAB
class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // Define the functionality shown at the top
  late final List<Functionality> _actions = actions;

  static void _toast(BuildContext c, String msg) =>
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Fixed header - stays at top
          Padding(padding: screenPadding, child: _buildHeader(context)),
          // Scrollable content with bounce effect
          Expanded(
            child: CustomScrollView(
              physics:
                  const AlwaysScrollableScrollPhysics(), // iOS-style bounce
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenPadding.left + 12,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: QuickActionsGrid(items: _actions),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenPadding.left + 12,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: RecentFilesSection(
                      onGetStartedPrimary: () =>
                          _toast(context, 'Scan a document'),
                      onGetStartedSecondary: () =>
                          _toast(context, 'Import PDF'),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Reused header
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      child: Row(
        children: [
          // Left: app glyph
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.widgets_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Files',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              context.goNamed(AppRouteName.filesRoot);
              context.pushNamed(
                AppRouteName.filesSearch,
                queryParameters: {'path': '/'},
              );
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
            tooltip: 'More',
          ),
        ],
      ),
    );
  }
}

/// Grid that lays out the top functionality buttons.
class QuickActionsGrid extends StatelessWidget {
  final List<Functionality> items;

  const QuickActionsGrid({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: 108,
          ),
          itemBuilder: (_, i) => Center(child: FunctionButton(data: items[i])),
        );
      },
    );
  }
}

/// Section that renders either a recent files list or a "Get Started" card.
class RecentFilesSection extends StatefulWidget {
  final VoidCallback onGetStartedPrimary;
  final VoidCallback onGetStartedSecondary;

  const RecentFilesSection({
    Key? key,
    required this.onGetStartedPrimary,
    required this.onGetStartedSecondary,
  }) : super(key: key);

  /// External trigger to ask the section to reload its contents.
  /// Increment this notifier's value to request a refresh from other parts of the app.
  static final ValueNotifier<int> refreshNotifier = ValueNotifier<int>(0);

  @override
  State<RecentFilesSection> createState() => _RecentFilesSectionState();
}

class _RecentFilesSectionState extends State<RecentFilesSection> {
  late Future<List<FileInfo>> _recentFilesFuture;

  @override
  void initState() {
    super.initState();
    debugPrint('📱 [RecentFilesSection] initState called');
    _loadRecentFiles();
    RecentFilesSection.refreshNotifier.addListener(_onExternalRefresh);
  }

  void _onExternalRefresh() {
    if (mounted) setState(() => _loadRecentFiles());
  }

  void _loadRecentFiles() {
    debugPrint('🔄 [RecentFilesSection] Loading recent files...');
    _recentFilesFuture = RecentFilesService.getRecentFiles().then((result) {
      return result.fold(
        (error) {
          debugPrint('❌ [RecentFilesSection] Error loading: $error');
          return <FileInfo>[];
        },
        (files) {
          debugPrint('✅ [RecentFilesSection] Loaded ${files.length} files');
          if (files.isEmpty) {
            debugPrint('📭 [RecentFilesSection] Files list is EMPTY');
          } else {
            debugPrint('📄 [RecentFilesSection] Files:');
            for (var i = 0; i < files.length; i++) {
              debugPrint('   ${i + 1}. ${files[i].name} (${files[i].path})');
            }
          }
          return files;
        },
      );
    });
  }

  void _handleFileOpen(FileInfo file) {
    debugPrint('🔓 [RecentFilesSection] Opening file: ${file.name}');
    context.pushNamed(
      AppRouteName.showPdf,
      queryParameters: {'path': file.path},
    );
  }

  Future<void> _handleFileDelete(FileInfo file) async {
    debugPrint('🗑️ [RecentFilesSection] Deleting file: ${file.name}');
    final result = await RecentFilesService.removeRecentFile(file.path);

    result.fold(
      (error) {
        debugPrint('❌ [RecentFilesSection] Delete failed: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      (updatedFiles) {
        debugPrint(
          '✅ [RecentFilesSection] Delete successful. Remaining: ${updatedFiles.length}',
        );
        if (mounted) {
          setState(() => _loadRecentFiles());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from recent files')),
          );
        }
      },
    );
  }

  void _handleFileMenu(FileInfo file, String action) {
    debugPrint(
      '📋 [RecentFilesSection] Menu action "$action" for: ${file.name}',
    );
    switch (action) {
      case 'open':
        _handleFileOpen(file);
        break;
      case 'delete':
        _handleFileDelete(file);
        break;
      case 'rename':
        debugPrint('ℹ️ [RecentFilesSection] Rename not implemented yet');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rename feature coming soon')),
        );
        break;
      case 'share':
        debugPrint('📤 [RecentFilesSection] Share handled by DocEntryCard');
        break;
    }
  }

  @override
  void dispose() {
    RecentFilesSection.refreshNotifier.removeListener(_onExternalRefresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎨 [RecentFilesSection] Building widget');
    final title = Text(
      'Recent Files',
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );

    return FutureBuilder<List<FileInfo>>(
      future: _recentFilesFuture,
      builder: (context, snapshot) {
        debugPrint(
          '🔧 [RecentFilesSection] FutureBuilder state: ${snapshot.connectionState}',
        );

        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('⏳ [RecentFilesSection] Showing loading indicator');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 12),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          );
        }

        // Error state (show empty state)
        if (snapshot.hasError) {
          debugPrint(
            '⚠️ [RecentFilesSection] FutureBuilder error: ${snapshot.error}',
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 12),
              _GetStartedCard(
                primary: widget.onGetStartedPrimary,
                secondary: widget.onGetStartedSecondary,
              ),
            ],
          );
        }

        final files = snapshot.data ?? [];
        debugPrint(
          '📊 [RecentFilesSection] Rendering with ${files.length} files',
        );

        // Empty state - show Get Started card
        if (files.isEmpty) {
          debugPrint(
            '🎴 [RecentFilesSection] Showing Get Started card (empty state)',
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 12),
              _GetStartedCard(
                primary: widget.onGetStartedPrimary,
                secondary: widget.onGetStartedSecondary,
              ),
            ],
          );
        }

        // Has files - show list
        debugPrint(
          '📋 [RecentFilesSection] Showing list of ${files.length} files',
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                title,
                TextButton(
                  onPressed: () async {
                    debugPrint('🧹 [RecentFilesSection] Clear All pressed');
                    final result = await RecentFilesService.clearRecentFiles();
                    result.fold(
                      (error) {
                        debugPrint(
                          '❌ [RecentFilesSection] Clear All failed: $error',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $error')),
                        );
                      },
                      (_) {
                        debugPrint(
                          '✅ [RecentFilesSection] Clear All successful',
                        );
                        setState(() => _loadRecentFiles());
                      },
                    );
                  },
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // List of recent files
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final file = files[index];
                return DocEntryCard(
                  info: file,
                  onOpen: () => _handleFileOpen(file),
                  onMenu: (action) => _handleFileMenu(file, action),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// Beautiful empty state card for "Get Started".
class _GetStartedCard extends StatelessWidget {
  final VoidCallback primary;
  final VoidCallback secondary;

  const _GetStartedCard({required this.primary, required this.secondary});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withOpacity(0.10),
            cs.secondary.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, color: cs.primary, size: 34),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get started with your PDFs',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Scan documents or import files to see them here.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
