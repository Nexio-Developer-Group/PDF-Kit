import 'package:flutter/material.dart';
import 'package:pdf_kit/core/theme/app_theme.dart';
import 'package:pdf_kit/presentation/component/setting_tile.dart';
import 'package:pdf_kit/presentation/models/setting_info_type.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool darkMode = false;
  String language = "English (US)";
  String defaultSaveLocation = "Internal storage";
  String fileNamingScheme = "Auto-increment";
  String pdfCompression = "Balanced";
  String filterOptions = "All files";
  String gridLayout = "Adaptive";
  String contentFit = "Fit width";

  @override
  Widget build(BuildContext context) {
    final items = <SettingsItem>[
      SettingsItem(
        id: "language",
        title: "Language",
        subtitle: "Select any language you want",
        type: SettingsItemType.value,
        trailingText: language,
        leadingIcon: Icons.language,
        onTap: () {
          // open language screen / bottom sheet
        },
      ),
      SettingsItem(
        id: "default_save",
        title: "Default Save Location",
        subtitle: "Choose where all PDFs will be saved",
        type: SettingsItemType.navigation,
        leadingIcon: Icons.folder,
        onTap: () {
          // open choose folder screen
        },
      ),
      SettingsItem(
        id: "dark_mode",
        title: "Dark Mode",
        subtitle: "Switch between light and dark themes",
        type: SettingsItemType.toggle,
        leadingIcon: Icons.dark_mode,
        switchValue: darkMode,
        onChanged: (value) {
          setState(() {
            darkMode = value;
          });
          // also update theme provider if you have one
        },
      ),
      SettingsItem(
        id: "file_naming",
        title: "File Naming Scheme",
        subtitle: "Set how new files are named automatically",
        type: SettingsItemType.navigation,
        leadingIcon: Icons.text_fields,
        onTap: () {},
      ),
      SettingsItem(
        id: "pdf_compression",
        title: "PDF Compression",
        subtitle: "Set how new files are compressed automatically",
        type: SettingsItemType.navigation,
        leadingIcon: Icons.compress,
        onTap: () {},
      ),
      SettingsItem(
        id: "filter_options",
        title: "Filter Options",
        subtitle: "Choose which filters the app applies by default",
        type: SettingsItemType.navigation,
        leadingIcon: Icons.filter_list,
        onTap: () {},
      ),
      SettingsItem(
        id: "grid_view_layout",
        title: "Grid View Layout",
        subtitle: "Control how files and folders appear",
        type: SettingsItemType.navigation,
        leadingIcon: Icons.grid_view,
        onTap: () {},
      ),
      SettingsItem(
        id: "pdf_content_fit",
        title: "PDF Content Fit Mode",
        subtitle: "Choose how images and PDFs should fit",
        type: SettingsItemType.navigation,
        leadingIcon: Icons.crop_landscape,
        onTap: () {},
      ),
      SettingsItem(
        id: "help_center",
        title: "Help Center",
        subtitle: "Get help, FAQs, and answers",
        type: SettingsItemType.navigation,
        leadingIcon: Icons.help_outline,
        onTap: () {},
      ),
      SettingsItem(
        id: "about_pdfkit",
        title: "About PDF-Kit",
        subtitle: "View details about this app",
        type: SettingsItemType.navigation,
        leadingIcon: Icons.info_outline,
        onTap: () {},
      ),
      SettingsItem(
        id: "about_us",
        title: "About Us",
        subtitle: "Discover our vision and how we work",
        type: SettingsItemType.navigation,
        leadingIcon: Icons.group_outlined,
        onTap: () {},
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: screenPadding,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => SizedBox.shrink(),
                  itemBuilder: (context, index) {
                    return SettingsTile(item: items[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
            'PDF Kit',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          // const Spacer(),
          // IconButton(
          //   icon: const Icon(Icons.settings),
          //   onPressed: () {
          //     context.push('/settings');
          //   },
          //   tooltip: 'Settings',
          // ),
        ],
      ),
    );
  }
}
