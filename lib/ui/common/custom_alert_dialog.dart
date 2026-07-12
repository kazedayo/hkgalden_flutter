import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Shows a simple adaptive OK alert.
///
/// - **iOS 26+:** native Liquid Glass `UIAlertController` via
///   [AdaptiveAlertDialog]
/// - **iOS &lt; 26:** classic [CupertinoAlertDialog]
/// - **Android:** Material [AlertDialog]
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

/// Legacy widget form kept for call sites that still build a dialog tree.
///
/// Prefer [showCustomAlert] so iOS 26+ gets Liquid Glass. This widget remains
/// Cupertino/Material painted chrome (no native glass).
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

/// Generic dialog host for fully custom [builder] content.
///
/// For simple title/content OK alerts use [showCustomAlert] instead.
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
