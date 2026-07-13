import 'package:flutter/material.dart';

class ListDivider extends StatelessWidget {
  final double indent;

  const ListDivider({super.key, this.indent = 0});

  @override
  Widget build(BuildContext context) => Divider(
        height: 1,
        thickness: 1,
        indent: indent,
        color: Theme.of(context).dividerColor,
      );
}
