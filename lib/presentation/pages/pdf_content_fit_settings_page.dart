import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';

class PdfContentFitSettingsPage extends StatefulWidget {
  const PdfContentFitSettingsPage({super.key});

  @override
  State<PdfContentFitSettingsPage> createState() =>
      _PdfContentFitSettingsPageState();
}

class _PdfContentFitSettingsPageState extends State<PdfContentFitSettingsPage> {
  PdfContentFitMode _selectedMode = PdfContentFitMode.original;
  static const String _demoAssetPath = 'assets/demo_image.jpg';

  @override
  void initState() {
    super.initState();
    _loadCurrentMode();
  }

  Future<void> _loadCurrentMode() async {
    final modeString = Prefs.getString(Constants.pdfContentFitModeKey);
    if (modeString != null && mounted) {
      setState(() {
        _selectedMode = PdfContentFitMode.fromString(modeString);
      });
    }
  }

  Future<void> _setMode(PdfContentFitMode mode) async {
    await Prefs.setString(Constants.pdfContentFitModeKey, mode.value);
    setState(() {
      _selectedMode = mode;
    });

    if (mounted) {
      final t = AppLocalizations.of(context);
      AppSnackbar.show(
        t.t('pdf_content_fit_settings_applied_snackbar'),
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    const previewSquare = 56.0;
    const previewOriginalHeight = 56.0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: screenPadding,
          children: [
            Text(
              t.t('pdf_content_fit_settings_page_title'), // "Merge PDF"
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              t.t('pdf_content_fit_settings_description'),
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 16),

            Text(
              t.t('pdf_content_fit_settings_choose_mode_label'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),

            _FitModeCard(
              title: t.t('pdf_content_fit_mode_original_title'),
              description: t.t('pdf_content_fit_mode_original_description'),
              icon: Icons.photo_size_select_actual_outlined,
              isSelected: _selectedMode == PdfContentFitMode.original,
              onTap: () => _setMode(PdfContentFitMode.original),
              preview: const _OriginalDimensionsPreview(
                assetPath: _demoAssetPath,
                height: previewOriginalHeight,
              ),
              radio: Radio<PdfContentFitMode>(
                value: PdfContentFitMode.original,
                toggleable: false,
              ),
            ),
            const SizedBox(height: 10),

            _FitModeCard(
              title: t.t('pdf_content_fit_mode_fit_title'),
              description: t.t('pdf_content_fit_mode_fit_description'),
              icon: Icons.fit_screen_outlined,
              isSelected: _selectedMode == PdfContentFitMode.fit,
              onTap: () => _setMode(PdfContentFitMode.fit),
              preview: const _SquareImagePreview(
                assetPath: _demoAssetPath,
                size: previewSquare,
                fit: BoxFit.contain,
              ),
              radio: Radio<PdfContentFitMode>(
                value: PdfContentFitMode.fit,
                toggleable: false,
              ),
            ),
            const SizedBox(height: 10),

            _FitModeCard(
              title: t.t('pdf_content_fit_mode_crop_title'),
              description: t.t('pdf_content_fit_mode_crop_description'),
              icon: Icons.crop_outlined,
              isSelected: _selectedMode == PdfContentFitMode.crop,
              onTap: () => _setMode(PdfContentFitMode.crop),
              preview: const _SquareImagePreview(
                assetPath: _demoAssetPath,
                size: previewSquare,
                fit: BoxFit.cover,
              ),
              radio: Radio<PdfContentFitMode>(
                value: PdfContentFitMode.crop,
                toggleable: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FitModeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget preview;
  final Widget radio;

  const _FitModeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.preview,
    required this.radio,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isSelected
            ? cs.primaryContainer.withValues(alpha: 0.15)
            : Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isSelected
              ? BorderSide(color: cs.primary, width: 1.5)
              : (theme.brightness == Brightness.light
                    ? BorderSide(
                        color: cs.outline.withValues(alpha: 0.15),
                        width: 1,
                      )
                    : BorderSide.none),
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: 0,
            right: 12,
            top: 12,
            bottom: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              radio,
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color: isSelected ? cs.primary : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              preview,
            ],
          ),
        ),
      ),
    );
  }
}

class _SquareImagePreview extends StatelessWidget {
  final String assetPath;
  final double size;
  final BoxFit fit;

  const _SquareImagePreview({
    required this.assetPath,
    required this.size,
    required this.fit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Image.asset(
        assetPath,
        fit: fit,
        alignment: Alignment.center,
        errorBuilder: (c, e, s) => Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: cs.onSurfaceVariant,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _OriginalDimensionsPreview extends StatefulWidget {
  final String assetPath;
  final double height;

  const _OriginalDimensionsPreview({
    required this.assetPath,
    required this.height,
  });

  @override
  State<_OriginalDimensionsPreview> createState() =>
      _OriginalDimensionsPreviewState();
}

class _OriginalDimensionsPreviewState
    extends State<_OriginalDimensionsPreview> {
  double? _aspectRatio;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _OriginalDimensionsPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) {
      _stopListening();
      _aspectRatio = null;
      _resolve();
    }
  }

  void _resolve() {
    final provider = AssetImage(widget.assetPath);
    final stream = provider.resolve(const ImageConfiguration());
    _stream = stream;

    final listener = ImageStreamListener((info, _) {
      final w = info.image.width.toDouble();
      final h = info.image.height.toDouble();
      if (!mounted || h == 0) return;
      setState(() => _aspectRatio = w / h);
    });
    _listener = listener;
    stream.addListener(listener);
  }

  void _stopListening() {
    final stream = _stream;
    final listener = _listener;
    if (stream != null && listener != null) {
      stream.removeListener(listener);
    }
    _stream = null;
    _listener = null;
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final ratio = _aspectRatio ?? (4 / 3);
    final width = widget.height * ratio;

    return Container(
      width: width,
      height: widget.height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Image.asset(
        widget.assetPath,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (c, e, s) => Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: cs.onSurfaceVariant,
            size: 18,
          ),
        ),
      ),
    );
  }
}
