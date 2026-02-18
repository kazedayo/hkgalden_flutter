import 'package:flutter/material.dart';

class ErrorPage extends StatelessWidget {
  final String message;
  final Function onRetry;

  const ErrorPage({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 70,
              color: Colors.white38,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              message,
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(
              height: 8,
            ),
            OutlinedButton(
              onPressed: () => onRetry(),
              child: const Text('重新載入'),
            )
          ],
        ),
      );
}
