
import 'package:flutter/material.dart';
import 'package:pdf_kit/models/functionality_model.dart';

/// Reusable button for one functionality.
class FunctionButton extends StatelessWidget {
  final Functionality data;

  const FunctionButton({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tint = (data.color ?? Theme.of(context).colorScheme.primary);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => data.onPressed(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: tint.withAlpha((0.12*225).toInt()),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: tint, size: 26),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 80,
            child: Text(
              data.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
