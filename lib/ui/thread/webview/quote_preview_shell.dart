import 'package:flutter/services.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview_shell.dart';

const String kQuotePreviewHtmlAsset = 'assets/thread_webview/quote_preview.html';
const String kQuotePreviewJsAsset = 'assets/thread_webview/quote_preview.js';

Future<String> loadQuotePreviewShell() async {
  final html = await rootBundle.loadString(kQuotePreviewHtmlAsset);
  final css = await rootBundle.loadString(kThreadWebViewCssAsset);
  final bridgeJs = await rootBundle.loadString(kThreadWebViewBridgeAsset);
  final previewJs = await rootBundle.loadString(kQuotePreviewJsAsset);
  return inlineWebViewShell(
    html: html,
    css: css,
    scripts: {
      'quote_preview.js': previewJs,
      'bridge.js': bridgeJs,
    },
  );
}
