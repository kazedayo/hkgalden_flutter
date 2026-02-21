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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '#$label',
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: Theme.of(context).colorScheme.onSecondary,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
