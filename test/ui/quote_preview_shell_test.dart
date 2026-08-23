import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/ui/thread/webview/quote_preview_shell.dart';

void main() {
  test('inlines css and scripts and strips external asset urls', () {
    const html = '''
<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="thread.css">
</head>
<body>
  <script src="quote_preview.js"></script>
  <script src="bridge.js"></script>
</body>
</html>
''';
    final out = inlineQuotePreviewShell(
      html: html,
      css: 'body{color:red}',
      bridgeJs: 'var a=1;',
      previewJs: 'var b=2;',
    );
    expect(out, contains('<style>\nbody{color:red}\n</style>'));
    expect(out, contains('<script>\nvar a=1;\n</script>'));
    expect(out, contains('<script>\nvar b=2;\n</script>'));
    expect(out, isNot(contains('thread.css')));
    expect(out, isNot(contains('src="bridge.js"')));
    expect(out, isNot(contains('src="quote_preview.js"')));
  });

  test('inlines real quote preview assets without leftover urls', () {
    final html =
        File('assets/thread_webview/quote_preview.html').readAsStringSync();
    final css = File('assets/thread_webview/thread.css').readAsStringSync();
    final bridgeJs = File('assets/thread_webview/bridge.js').readAsStringSync();
    final previewJs =
        File('assets/thread_webview/quote_preview.js').readAsStringSync();
    final out = inlineQuotePreviewShell(
      html: html,
      css: css,
      bridgeJs: bridgeJs,
      previewJs: previewJs,
    );
    expect(out, contains('<style>'));
    expect(out, contains('<script>'));
    expect(out, contains(css));
    expect(out, contains(bridgeJs));
    expect(out, contains(previewJs));
    expect(out, isNot(contains('thread.css')));
    expect(out, isNot(contains('src="bridge.js"')));
    expect(out, isNot(contains('src="quote_preview.js"')));
  });

  test('real quote shell has content root and no thread chrome', () {
    final html =
        File('assets/thread_webview/quote_preview.html').readAsStringSync();
    expect(html, contains('id="content"'));
    expect(html, contains('class="comment-html"'));
    expect(html, contains('href="thread.css"'));
    expect(html, contains('src="quote_preview.js"'));
    expect(html, contains('pointer-events: none'));
    expect(html, isNot(contains('min-height: 100%')));
    expect(html, isNot(contains('margin-top: auto')));
    expect(html, isNot(contains('id="previous-pull"')));
    expect(html, isNot(contains('id="main"')));
    expect(html, isNot(contains('render.js')));
  });

  test('quote preview js has no click / openLink handlers', () {
    final js =
        File('assets/thread_webview/quote_preview.js').readAsStringSync();
    expect(js, contains('setHtml'));
    expect(js, contains('setTheme'));
    expect(js, contains('scrollTo'));
    expect(js, contains('contentHeight'));
    expect(js, contains('scrollHeight'));
    expect(js, isNot(contains('openLink')));
    expect(js, isNot(contains('click')));
  });
}
