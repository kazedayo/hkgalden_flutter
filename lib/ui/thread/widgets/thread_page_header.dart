import 'package:flutter/material.dart';

class ThreadPageHeader extends StatelessWidget {
  final int floor;

  const ThreadPageHeader({super.key, required this.floor});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 50,
        child: Center(
          child: Text(floor == 1 ? '第 1 頁' : '第 ${(floor + 49) ~/ 50} 頁'),
        ),
      );
}
