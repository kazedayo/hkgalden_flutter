import 'package:flutter/services.dart';

const String kThreadWebViewHtmlAsset = 'assets/thread_webview/index.html';
const String kThreadWebViewCssAsset = 'assets/thread_webview/thread.css';
const String kThreadWebViewBridgeAsset = 'assets/thread_webview/bridge.js';
const String kThreadWebViewRenderAsset = 'assets/thread_webview/render.js';

/// Inlines CSS/JS into the shell so the WebView never fetches (and caches)
/// sibling Flutter assets.
String inlineThreadWebViewShell({
  required String html,
  required String css,
  required String bridgeJs,
  required String renderJs,
}) {
  var result = html.replaceFirst(
    RegExp(r'<link\s+rel="stylesheet"\s+href="thread\.css[^"]*"\s*/?>'),
    '<style>\n$css\n</style>',
  );
  result = result.replaceFirst(
    RegExp(r'<script\s+src="bridge\.js[^"]*"\s*>\s*</script>'),
    '<script>\n$bridgeJs\n</script>',
  );
  result = result.replaceFirst(
    RegExp(r'<script\s+src="render\.js[^"]*"\s*>\s*</script>'),
    '<script>\n$renderJs\n</script>',
  );
  return result;
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
