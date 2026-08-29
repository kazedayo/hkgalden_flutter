import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_ui.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';

/// Largest font size where [title] fits in 2 lines at [maxWidth], in 18–14pt.
/// Memoized per title+width; unbounded but one tiny entry per thread viewed.
final _fittingFontSizeCache = <String, double>{};

double fittingFontSize(String title, double maxWidth) {
  final key = '$title\u001f$maxWidth';
  return _fittingFontSizeCache[key] ??= _computeFittingFontSize(title, maxWidth);
}

double _computeFittingFontSize(String title, double maxWidth) {
  for (var fontSize = 18.0; fontSize >= 14.0; fontSize -= 1) {
    final painter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: fontSize),
      ),
      maxLines: 2,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    if (!painter.didExceedMaxLines) {
      return fontSize;
    }
  }
  return 14;
}

PreferredSizeWidget buildThreadPageAppBar(
  BuildContext context,
  ThreadPageArguments arguments,
  ThreadPageUi pageUi,
) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: ValueListenableBuilder<double>(
      valueListenable: pageUi.elevation,
      builder: (context, elevation, _) => AppBar(
        elevation: elevation,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Theme.of(context).platform == TargetPlatform.iOS
              ? Icons.arrow_back_ios_rounded
              : Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: LayoutBuilder(
          builder: (context, constraints) => Text(
            arguments.title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: fittingFontSize(arguments.title,
                  constraints.maxWidth),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          Visibility(
            visible: arguments.locked,
            child: const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(Icons.lock_rounded),
            ),
          )
        ],
      ),
    ),
  );
}
