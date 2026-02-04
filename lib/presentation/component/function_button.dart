import 'package:flutter/material.dart';
import 'package:pdf_kit/models/functionality_model.dart';

/// Reusable button for one functionality.
class FunctionButton extends StatelessWidget {
  final Functionality data;

  const FunctionButton({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final tint = (data.color ?? Theme.of(context).colorScheme.primary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => data.onPressed(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // height = icon + dynamic text
            children: [
              Ink(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Theme.of(context).brightness == Brightness.dark
                      ? Border.all(
                          color: tint.withValues(alpha: 0.3),
                          width: 1.5,
                        )
                      : null,
                ),
                child: Icon(data.icon, color: tint, size: 26),
              ),
              const SizedBox(height: 6),
              // Dynamic height (only width is constrained)
              SizedBox(
                width: 80, // keep horizontal footprint stable
                child: Text(
                  data.label,
                  textAlign: TextAlign.center,
                  maxLines: 2, // or 3 if you want more
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
