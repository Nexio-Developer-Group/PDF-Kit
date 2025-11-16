import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/models/functionality_list.dart';
import 'package:pdf_kit/models/functionality_model.dart';
import 'package:pdf_kit/presentation/component/function_button.dart';

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
              physics: const BouncingScrollPhysics(), // iOS-style bounce
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

  // Reused header (exactly your snippet)
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      child: Row(
        children: [
          // Left: app glyph (simple circle + star to emulate Files brand feel)
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
              // Option A: open Files-scoped search on top of Files branch
              context.goNamed(AppRouteName.filesRoot); // switch to Files tab
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
        // 4 columns like your screenshot
        const crossAxisCount = 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: 108, // room for label
          ),
          itemBuilder: (_, i) => Center(child: FunctionButton(data: items[i])),
        );
      },
    );
  }
}

/// Section that renders either a recent files list or a "Get Started" card.
class RecentFilesSection extends StatelessWidget {
  final VoidCallback onGetStartedPrimary;
  final VoidCallback onGetStartedSecondary;

  const RecentFilesSection({
    Key? key,
    required this.onGetStartedPrimary,
    required this.onGetStartedSecondary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title = Text(
      'Recent Files',
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );

    // if (files.isEmpty) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: 12),
        _GetStartedCard(
          primary: onGetStartedPrimary,
          secondary: onGetStartedSecondary,
        ),
      ],
    );
    // }
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
