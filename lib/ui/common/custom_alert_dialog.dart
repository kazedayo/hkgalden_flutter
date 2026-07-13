import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Adaptive OK alert (Liquid Glass on iOS 26+, Cupertino/Material otherwise).
Future<void> showCustomAlert({
  required BuildContext context,
  required String title,
  required String content,
  String okLabel = 'OK',
}) {
  return AdaptiveAlertDialog.show(
    context: context,
    title: title,
    message: content,
    actions: [
      AlertAction(
        title: okLabel,
        style: AlertActionStyle.primary,
        onPressed: () {},
      ),
    ],
  );
}

/// Prefer [showCustomAlert] for iOS 26+ Liquid Glass.
class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;

  const CustomAlertDialog(
      {super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) =>
      Theme.of(context).platform == TargetPlatform.iOS
          ? CupertinoAlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            )
          : AlertDialog(
              title: Text(
                title,
              ),
              content: Text(
                content,
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                ),
              ],
            );
}

void showCustomDialog({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
}) =>
    Theme.of(context).platform == TargetPlatform.iOS
        ? showCupertinoDialog(
            context: context,
            builder: builder,
          )
        : showModal(
            context: context,
            builder: builder,
          );
