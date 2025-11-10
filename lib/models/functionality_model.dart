
import 'package:flutter/widgets.dart';

/// MODEL: a single quick-action shown in the top grid.
typedef ActionHandler = void Function(BuildContext context);


class Functionality {
  final String id;
  final String label;
  final IconData icon;
  final Color? color;
  final ActionHandler onPressed;

  Functionality({
    required this.id,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });
}