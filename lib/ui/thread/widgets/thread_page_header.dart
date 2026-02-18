part of '../thread_page.dart';

class _PageHeader extends StatelessWidget {
  final int floor;

  const _PageHeader({required this.floor});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 50,
        child: Center(
          child: Text(floor == 1 ? '第 1 頁' : '第 ${(floor + 49) ~/ 50} 頁'),
        ),
      );
}
