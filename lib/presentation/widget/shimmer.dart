import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Base wrapper you can reuse anywhere.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration period;
  final bool enabled;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.baseColor,
    this.highlightColor,
    this.period = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base =
        baseColor ??
        theme.colorScheme.surfaceContainerHighest.withAlpha(
          (0.6 * 225).toInt(),
        );
    final hi =
        highlightColor ??
        theme.colorScheme.surface.withAlpha((0.9 * 225).toInt());

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: hi,
      period: period, // animation speed. [web:47]
      enabled: enabled,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: base, borderRadius: borderRadius),
      ),
    );
  }
}

/// Line placeholder (e.g., title/subtitle)
class ShimmerLine extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  final Duration period;

  const ShimmerLine({
    super.key,
    this.width = double.infinity,
    this.height = 12,
    this.radius = 6,
    this.period = const Duration(milliseconds: 1400),
  });

  @override
  Widget build(BuildContext context) => ShimmerBox(
    width: width,
    height: height,
    borderRadius: BorderRadius.circular(radius),
    period: period,
  );
}

/// Circle placeholder (e.g., avatar/thumbnail)
class ShimmerCircle extends StatelessWidget {
  final double size;
  final Duration period;

  const ShimmerCircle({
    super.key,
    this.size = 48,
    this.period = const Duration(milliseconds: 1400),
  });

  @override
  Widget build(BuildContext context) => ShimmerBox(
    width: size,
    height: size,
    borderRadius: BorderRadius.circular(size / 2),
    period: period,
  );
}

/// List skeleton commonly used for file tiles.
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry padding;
  final double gap;

  const ShimmerList({
    super.key,
    this.itemCount = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    this.gap = 12,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: gap),
      itemBuilder: (context, index) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            ShimmerCircle(size: 44),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLine(width: double.infinity, height: 12),
                  SizedBox(height: 8),
                  ShimmerLine(width: 160, height: 10),
                ],
              ),
            ),
            SizedBox(width: 12),
            ShimmerLine(width: 28, height: 12), // trailing meta
          ],
        );
      },
    );
  }
}
