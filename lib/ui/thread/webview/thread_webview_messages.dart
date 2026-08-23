import 'dart:convert';

const Set<String> kThreadWebViewInboundTypes = {
  'ready',
  'contentReady',
  'openLink',
  'openImage',
  'quote',
  'openUser',
  'scroll',
  'pullPrevious',
  'refreshLastPage',
  'imageMetrics',
  'contentHeight',
};

/// Parsed JS → Dart message. Unknown or malformed payloads are dropped.
class ThreadWebViewInbound {
  final String type;
  final Map<String, dynamic> payload;

  const ThreadWebViewInbound({required this.type, required this.payload});

  static ThreadWebViewInbound? tryParse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      final type = decoded['type'];
      if (type is! String || !kThreadWebViewInboundTypes.contains(type)) {
        return null;
      }
      final payload = decoded['payload'];
      return ThreadWebViewInbound(
        type: type,
        payload: payload is Map
            ? Map<String, dynamic>.from(payload)
            : const <String, dynamic>{},
      );
    } catch (_) {
      return null;
    }
  }

  String? string(String key) {
    final value = payload[key];
    return value is String ? value : null;
  }

  int? integer(String key) {
    final value = payload[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  double? decimal(String key) {
    final value = payload[key];
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  bool flag(String key, {bool fallback = false}) {
    final value = payload[key];
    if (value is bool) {
      return value;
    }
    return fallback;
  }
}

bool isHttpOrHttpsUrl(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) {
    return false;
  }
  return uri.scheme == 'http' || uri.scheme == 'https';
}
