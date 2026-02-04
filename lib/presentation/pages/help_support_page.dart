import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _selectedSection = 'help_section_all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final faqs = _faqItems(t);

    final normalizedQuery = _query.trim().toLowerCase();

    // Filter by section first
    var filtered = _selectedSection == 'help_section_all'
        ? faqs
        : faqs.where((f) => f.section == _selectedSection).toList();

    // Then filter by search query
    if (normalizedQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (f) =>
                f.question.toLowerCase().contains(normalizedQuery) ||
                f.answer.toLowerCase().contains(normalizedQuery),
          )
          .toList(growable: false);
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.t('settings_help_center_title'))),
      body: SafeArea(
        child: Padding(
          padding: screenPadding,
          child: Column(
            children: [
              // Section chips
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final sectionKey in [
                      'help_section_all',
                      'help_section_general',
                      'help_section_features',
                      'help_section_files',
                      'help_section_troubleshooting',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selectedColor: Theme.of(context).colorScheme.primary,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          label: Text(
                            t.t(sectionKey),
                            style: TextStyle(
                              color: _selectedSection == sectionKey
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          selected: _selectedSection == sectionKey,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedSection = sectionKey);
                            }
                          },
                          checkmarkColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: _selectedSection == sectionKey
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: t.t('help_search_hint'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.trim().isEmpty
                        ? null
                        : IconButton(
                            tooltip: t.t('help_clear_tooltip'),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            t.t('help_no_results'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      )
                    : ListView.separated(
                        // padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return Card(
                            elevation: 0,
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.1),
                              ),
                            ),
                            child: ExpansionTile(
                              shape: const Border(),
                              collapsedShape: const Border(),
                              title: Text(
                                item.question,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.2),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      item.answer,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(height: 1.4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_FaqItem> _faqItems(AppLocalizations t) {
    return [
      // General
      _FaqItem(
        section: 'help_section_general',
        question: t.t('help_faq_general_1_question'),
        answer: t.t('help_faq_general_1_answer'),
      ),
      _FaqItem(
        section: 'help_section_general',
        question: t.t('help_faq_general_2_question'),
        answer: t.t('help_faq_general_2_answer'),
      ),
      _FaqItem(
        section: 'help_section_general',
        question: t.t('help_faq_general_3_question'),
        answer: t.t('help_faq_general_3_answer'),
      ),
      // Features
      _FaqItem(
        section: 'help_section_features',
        question: t.t('help_faq_features_1_question'),
        answer: t.t('help_faq_features_1_answer'),
      ),
      _FaqItem(
        section: 'help_section_features',
        question: t.t('help_faq_features_2_question'),
        answer: t.t('help_faq_features_2_answer'),
      ),
      _FaqItem(
        section: 'help_section_features',
        question: t.t('help_faq_features_3_question'),
        answer: t.t('help_faq_features_3_answer'),
      ),
      _FaqItem(
        section: 'help_section_features',
        question: t.t('help_faq_features_4_question'),
        answer: t.t('help_faq_features_4_answer'),
      ),
      _FaqItem(
        section: 'help_section_features',
        question: t.t('help_faq_features_5_question'),
        answer: t.t('help_faq_features_5_answer'),
      ),
      _FaqItem(
        section: 'help_section_features',
        question: t.t('help_faq_features_6_question'),
        answer: t.t('help_faq_features_6_answer'),
      ),
      _FaqItem(
        section: 'help_section_features',
        question: t.t('help_faq_features_7_question'),
        answer: t.t('help_faq_features_7_answer'),
      ),
      // Files
      _FaqItem(
        section: 'help_section_files',
        question: t.t('help_faq_files_1_question'),
        answer: t.t('help_faq_files_1_answer'),
      ),
      // Troubleshooting
      _FaqItem(
        section: 'help_section_troubleshooting',
        question: t.t('help_faq_troubleshooting_1_question'),
        answer: t.t('help_faq_troubleshooting_1_answer'),
      ),
      _FaqItem(
        section: 'help_section_files',
        question: t.t('help_faq_files_2_question'),
        answer: t.t('help_faq_files_2_answer'),
      ),
      _FaqItem(
        section: 'help_section_troubleshooting',
        question: t.t('help_faq_troubleshooting_2_question'),
        answer: t.t('help_faq_troubleshooting_2_answer'),
      ),
    ];
  }
}

class _FaqItem {
  final String question;
  final String answer;
  final String section;

  const _FaqItem({
    required this.question,
    required this.answer,
    required this.section,
  });
}
