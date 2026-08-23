import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/thread/webview/quote_preview_shell.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview_document.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview_js.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview_messages.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview_theme.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';
import 'package:webview_flutter/webview_flutter.dart';

class QuotePreviewWebView extends StatefulWidget {
  final String html;

  const QuotePreviewWebView({super.key, required this.html});

  @override
  State<QuotePreviewWebView> createState() => _QuotePreviewWebViewState();
}

class _QuotePreviewWebViewState extends State<QuotePreviewWebView> {
  static const _smileyHost = 's.hkgalden.org';
  static const _smileyPathPrefix = '/smilies/';

  late final WebViewController _controller;
  late final ThreadWebViewJs _js;
  double? _contentHeight;

  @override
  void initState() {
    super.initState();
    _js = ThreadWebViewJs();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.backgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: _onNavigation),
      )
      ..addJavaScriptChannel(
        'Galden',
        onMessageReceived: (message) {
          final inbound = ThreadWebViewInbound.tryParse(message.message);
          if (inbound != null && mounted) {
            _onInbound(inbound);
          }
        },
      );
    _js.attach(_controller);
    _loadShell();
  }

  Future<void> _loadShell() async {
    final html = await loadQuotePreviewShell();
    if (!mounted) {
      return;
    }
    await _controller.loadHtmlString(html, baseUrl: 'about:blank');
  }

  void _onInbound(ThreadWebViewInbound message) {
    switch (message.type) {
      case 'ready':
        _onReady();
      case 'contentHeight':
        _onContentHeight(message.decimal('height'));
    }
  }

  void _onReady() {
    _js.onReady();
    _pushContent();
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
    _js.send('setTheme', threadWebViewThemeTokens());
    final rewritten = const ThreadWebViewDocument().rewriteContentHtml(
      widget.html,
      leanPreview: true,
    );
    _js.send('setHtml', {'html': rewritten.html});
  }

  @override
  void didUpdateWidget(covariant QuotePreviewWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.html != widget.html && _js.isReady) {
      _pushContent();
    }
  }

  NavigationDecision _onNavigation(NavigationRequest request) {
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _contentHeight ?? 1,
      width: double.infinity,
      child: WebViewWidget(controller: _controller),
    );
  }
}
