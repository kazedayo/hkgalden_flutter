import 'package:flutter/material.dart';

/// A small inline widget that shows an [icon] followed by a 5px gap and
/// then [child], all within a [Text.rich] so baseline alignment is preserved.
class IconTextItem extends StatelessWidget {
  final IconData icon;
  final Widget child;
  final double iconSize;

  const IconTextItem({
    super.key,
    required this.icon,
    required this.child,
    this.iconSize = 13,
  });

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              child: Icon(icon, size: iconSize),
              alignment: PlaceholderAlignment.middle,
            ),
            const WidgetSpan(child: SizedBox(width: 5)),
            WidgetSpan(child: child),
          ],
        ),
      );
}
