import 'dart:convert';

import 'package:webview_flutter/webview_flutter.dart';

/// Queues Dart → JS commands until the shell posts `ready`.
class ThreadWebViewJs {
  WebViewController? _controller;
  bool _ready = false;
  final List<Map<String, dynamic>> _queue = [];

  bool get isReady => _ready;

  void attach(WebViewController controller) {
    _controller = controller;
  }

  Future<void> onReady() async {
    _ready = true;
    final pending = List<Map<String, dynamic>>.from(_queue);
    _queue.clear();
    for (final command in pending) {
      await _send(command);
    }
  }

  Future<void> send(String type, [Map<String, dynamic>? payload]) async {
    final command = <String, dynamic>{
      'type': type,
      'payload': payload ?? <String, dynamic>{},
    };
    if (!_ready) {
      _queue.add(command);
      return;
    }
    await _send(command);
  }

  Future<void> _send(Map<String, dynamic> command) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    final js = 'window.GaldenBridge.receive(${jsonEncode(command)});';
    await controller.runJavaScript(js);
  }
}
