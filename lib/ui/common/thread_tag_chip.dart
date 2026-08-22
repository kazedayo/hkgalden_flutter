import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';

class ThreadTagChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;

  static const BorderRadius _radius =
      BorderRadius.all(Radius.circular(AppTheme.radiusSmall));

  const ThreadTagChip({
    super.key,
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: _radius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          '#$label',
          style: theme.textTheme.labelSmall!.copyWith(
            color: theme.colorScheme.onSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
