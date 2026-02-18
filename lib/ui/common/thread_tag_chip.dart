import 'package:flutter/material.dart';

class ThreadTagChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;

  const ThreadTagChip({
    super.key,
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      label: Text(
        '#$label',
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: Theme.of(context).colorScheme.onSecondary,
            fontWeight: FontWeight.w600),
      ),
      backgroundColor: backgroundColor,
      side: BorderSide.none,
    );
  }
}
