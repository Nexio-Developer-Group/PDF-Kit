import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/models/functionality_model.dart';
import 'package:pdf_kit/presentation/component/function_button.dart';

/// HOME TAB
class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final String _currentPath = '/';

  // Define the functionality shown at the top
  late final List<Functionality> _actions = [
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

  static void _toast(BuildContext c, String msg) =>
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          // Top functionality grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverToBoxAdapter(
              child: QuickActionsGrid(items: _actions),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          // Recent files section
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverToBoxAdapter(
              child: RecentFilesSection(
                onGetStartedPrimary: () => _toast(context, 'Scan a document'),
                onGetStartedSecondary: () => _toast(context, 'Import PDF'),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
              // Go to dedicated search screen, pass the current path.
              Navigator.pushNamed(
                context,
                AppRoutes.search,
                arguments: {'path': _currentPath},
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
