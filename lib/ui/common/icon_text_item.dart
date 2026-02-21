import 'package:flutter/material.dart';

class IconTextItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final double iconSize;
  final TextStyle? textStyle;

  const IconTextItem({
    super.key,
    required this.icon,
    required this.text,
    this.iconSize = 13,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: textStyle?.color,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: textStyle,
        ),
      ],
    );
  }
}
