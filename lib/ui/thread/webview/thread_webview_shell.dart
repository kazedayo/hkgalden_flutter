import 'package:flutter/services.dart';

const String kThreadWebViewHtmlAsset = 'assets/thread_webview/index.html';
const String kThreadWebViewCssAsset = 'assets/thread_webview/thread.css';
const String kThreadWebViewBridgeAsset = 'assets/thread_webview/bridge.js';
const String kThreadWebViewRenderAsset = 'assets/thread_webview/render.js';

/// Inlines CSS/JS so the WebView never fetches sibling Flutter assets.
/// Throws [StateError] if a marker is missing or still present after replace.
String inlineWebViewShell({
  required String html,
  required String css,
  required Map<String, String> scripts,
}) {
  var result = _replaceRequired(
    html,
    RegExp(r'<link\s+rel="stylesheet"\s+href="thread\.css[^"]*"\s*/?>'),
    '<style>\n$css\n</style>',
    'thread.css',
  );
  for (final entry in scripts.entries) {
    result = _replaceRequired(
      result,
      RegExp(
        '<script\\s+src="${RegExp.escape(entry.key)}[^"]*"\\s*>\\s*</script>',
      ),
      '<script>\n${entry.value}\n</script>',
      entry.key,
    );
  }
  return result;
}

String _replaceRequired(
  String html,
  RegExp pattern,
  String replacement,
  String marker,
) {
  if (!pattern.hasMatch(html)) {
    throw StateError('Missing $marker in webview shell');
  }
  final result = html.replaceFirst(pattern, replacement);
  if (pattern.hasMatch(result)) {
    throw StateError('Leftover $marker in webview shell');
  }
  return result;
}

String inlineThreadWebViewShell({
  required String html,
  required String css,
  required String bridgeJs,
  required String renderJs,
}) {
  return inlineWebViewShell(
    html: html,
    css: css,
    scripts: {
      'bridge.js': bridgeJs,
      'render.js': renderJs,
    },
  );
}

Future<String> loadThreadWebViewShell() async {
  final html = await rootBundle.loadString(kThreadWebViewHtmlAsset);
  final css = await rootBundle.loadString(kThreadWebViewCssAsset);
  final bridgeJs = await rootBundle.loadString(kThreadWebViewBridgeAsset);
  final renderJs = await rootBundle.loadString(kThreadWebViewRenderAsset);
  return inlineThreadWebViewShell(
    html: html,
    css: css,
    bridgeJs: bridgeJs,
    renderJs: renderJs,
  );
}
