import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/thread/webview/quote_preview_shell.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview_document.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview_js.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview_messages.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview_theme.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// One shared, pre-warmed WebView for quote previews. Creating a fresh
/// WebViewController per compose session costs noticeable startup time;
/// reusing a loaded shell makes previews appear near-instantly.
class QuotePreviewWebViewHost {
  QuotePreviewWebViewHost._() {
    js.attach(controller);
  }

  static final instance = QuotePreviewWebViewHost._();

  static const _smileyHost = 's.hkgalden.org';
  static const _smileyPathPrefix = '/smilies/';

  final ThreadWebViewJs js = ThreadWebViewJs();

  late final WebViewController controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(AppTheme.backgroundColor)
    ..setNavigationDelegate(
      NavigationDelegate(onNavigationRequest: _onNavigation),
    )
    ..addJavaScriptChannel(
      'Galden',
      onMessageReceived: (message) {
        final inbound = ThreadWebViewInbound.tryParse(message.message);
        if (inbound == null) {
          return;
        }
        if (inbound.type == 'ready') {
          instance.js.onReady();
        }
        instance.listener?.call(inbound);
      },
    );

  /// Inbound handler of the currently mounted preview, if any.
  void Function(ThreadWebViewInbound)? listener;

  bool _prewarmed = false;

  void prewarm() {
    if (_prewarmed) {
      return;
    }
    _prewarmed = true;
    loadQuotePreviewShell().then(
      (html) => controller.loadHtmlString(html, baseUrl: 'about:blank'),
    );
  }

  static NavigationDecision _onNavigation(NavigationRequest request) {
    final url = request.url;
    if (url == 'about:blank' || url.startsWith('data:')) {
      return NavigationDecision.navigate;
    }
    final uri = Uri.tryParse(url);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host == _smileyHost &&
        uri.path.startsWith(_smileyPathPrefix)) {
      return NavigationDecision.navigate;
    }
    return NavigationDecision.prevent;
  }
}

class QuotePreviewWebView extends StatefulWidget {
  final String html;

  const QuotePreviewWebView({super.key, required this.html});

  @override
  State<QuotePreviewWebView> createState() => _QuotePreviewWebViewState();
}

class _QuotePreviewWebViewState extends State<QuotePreviewWebView> {
  double? _contentHeight;

  QuotePreviewWebViewHost get _host => QuotePreviewWebViewHost.instance;

  @override
  void initState() {
    super.initState();
    _host.listener = _onInbound;
    _host.prewarm();
    if (_host.js.isReady) {
      _pushContent();
    }
  }

  @override
  void dispose() {
    if (identical(_host.listener, _onInbound)) {
      _host.listener = null;
    }
    super.dispose();
  }

  void _onInbound(ThreadWebViewInbound message) {
    if (!mounted) {
      return;
    }
    switch (message.type) {
      case 'ready':
        _pushContent();
      case 'contentHeight':
        _onContentHeight(message.decimal('height'));
    }
  }

  void _onContentHeight(double? height) {
    if (height == null || height < 0) {
      return;
    }
    final previous = _contentHeight;
    if (previous != null && (height - previous).abs() < 1) {
      return;
    }
    setState(() => _contentHeight = height);
  }

  void _pushContent() {
    _host.js.send('setTheme', threadWebViewThemeTokens());
    final rewritten = const ThreadWebViewDocument().rewriteContentHtml(
      widget.html,
      leanPreview: true,
    );
    _host.js.send('setHtml', {'html': rewritten.html});
  }

  @override
  void didUpdateWidget(covariant QuotePreviewWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html && _host.js.isReady) {
      _pushContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _contentHeight ?? 1,
      width: double.infinity,
      child: WebViewWidget(controller: _host.controller),
    );
  }
}
