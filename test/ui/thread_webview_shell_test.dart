import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview_shell.dart';

void main() {
  test('inlines css and scripts and strips external asset urls', () {
    const html = '''
<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="thread.css">
</head>
<body>
  <script src="bridge.js"></script>
  <script src="render.js"></script>
</body>
</html>
''';
    final out = inlineThreadWebViewShell(
      html: html,
      css: 'body{color:red}',
      bridgeJs: 'var a=1;',
      renderJs: 'var b=2;',
    );
    expect(out, contains('<style>\nbody{color:red}\n</style>'));
    expect(out, contains('<script>\nvar a=1;\n</script>'));
    expect(out, contains('<script>\nvar b=2;\n</script>'));
    expect(out, isNot(contains('thread.css')));
    expect(out, isNot(contains('src="bridge.js"')));
    expect(out, isNot(contains('src="render.js"')));
  });

  test('inlines even when href has a leftover cache query', () {
    const html =
        '<link rel="stylesheet" href="thread.css?v=9"><script src="bridge.js?v=9"></script><script src="render.js?v=9"></script>';
    final out = inlineThreadWebViewShell(
      html: html,
      css: 'x',
      bridgeJs: 'y',
      renderJs: 'z',
    );
    expect(out, contains('<style>\nx\n</style>'));
    expect(out, isNot(contains('?v=')));
  });

  test('real shell html includes the previous-page pull header', () {
    final html = File('assets/thread_webview/index.html').readAsStringSync();
    expect(html, contains('id="previous-pull"'));
    expect(html, contains('href="thread.css"'));
  });

  test('empty avatar uses the native hkgalden placeholder svg', () {
    final js = File('assets/thread_webview/render.js').readAsStringSync();
    final css = File('assets/thread_webview/thread.css').readAsStringSync();
    expect(js, contains('class="avatar placeholder"'));
    expect(js, contains('viewBox="0 0 512 512"'));
    expect(js, contains('M150.9,370.2'));
    expect(js, contains('M319.3,399.6'));
    expect(js, isNot(contains('<span class="avatar placeholder"></span>')));
    expect(css, contains('.avatar.placeholder'));
    expect(
      css,
      contains(RegExp(r'\.avatar\.placeholder\s*\{[^}]*color:\s*var\(--text-secondary\)')),
    );
  });

  test('chrome buttons drop tap highlight; links and embeds keep it', () {
    final css = File('assets/thread_webview/thread.css').readAsStringSync();
    final avatarRule =
        RegExp(r'\.avatar-btn\s*\{[^}]*-webkit-tap-highlight-color:\s*transparent');
    final quoteRule =
        RegExp(r'\.quote-btn\s*\{[^}]*-webkit-tap-highlight-color:\s*transparent');
    final previewRule = RegExp(
        r'\.preview-chip\s*\{[^}]*-webkit-tap-highlight-color:\s*transparent');
    final linkRule = RegExp(
        r'\.comment-html a\s*\{[^}]*-webkit-tap-highlight-color:\s*transparent');
    expect(css, contains(avatarRule));
    expect(css, contains(quoteRule));
    expect(css, isNot(contains(previewRule)));
    expect(css, isNot(contains(linkRule)));
  });
}
