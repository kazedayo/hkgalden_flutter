import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:hkgalden_flutter/utils/inflight_cache.dart';

class XStatusInfo {
  final String authorName;
  final String? authorScreenName;
  final String? authorUrl;
  final String text;
  final String? imageUrl;

  const XStatusInfo({
    required this.authorName,
    this.authorScreenName,
    this.authorUrl,
    required this.text,
    this.imageUrl,
  });
}

/// In-memory FxTwitter status cache (avoids re-fetch on list rebuild).
class XStatusCache {
  XStatusCache._({http.Client? client}) : _client = client ?? http.Client();

  static final XStatusCache instance = XStatusCache._();

  final http.Client _client;
  final InflightCache<String, XStatusInfo?> _cache = InflightCache();

  factory XStatusCache.forTesting(http.Client client) {
    return XStatusCache._(client: client);
  }

  Future<XStatusInfo?> fetch(String statusId) {
    return _cache.get(statusId, () => _load(statusId));
  }

  Future<XStatusInfo?> _load(String statusId) async {
    final uri = Uri.https('api.fxtwitter.com', '/2/status/$statusId');
    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return null;
      }
      return parseResponse(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  /// Visible for tests.
  static XStatusInfo? parseResponse(Map<String, dynamic> decoded) {
    final code = decoded['code'];
    if (code is int && code != 200) {
      return null;
    }

    final statusRaw = decoded['status'];
    if (statusRaw is! Map) {
      return null;
    }
    final status = Map<String, dynamic>.from(statusRaw);

    final authorRaw = status['author'];
    if (authorRaw is! Map) {
      return null;
    }
    final author = Map<String, dynamic>.from(authorRaw);

    final authorName = author['name'];
    final name = authorName is String && authorName.isNotEmpty
        ? authorName
        : (author['screen_name'] is String
            ? author['screen_name'] as String
            : null);
    if (name == null || name.isEmpty) {
      return null;
    }

    final textRaw = status['text'];
    final text = textRaw is String ? textRaw.trim() : '';

    final screenName = author['screen_name'] is String
        ? author['screen_name'] as String
        : null;
    final authorUrl = author['url'] is String
        ? author['url'] as String
        : (screenName != null ? 'https://x.com/$screenName' : null);

    return XStatusInfo(
      authorName: name,
      authorScreenName: screenName,
      authorUrl: authorUrl,
      text: text,
      imageUrl: firstMediaImageUrl(status['media']),
    );
  }

  /// Prefer photos; fall back to video/gif thumbnails.
  static String? firstMediaImageUrl(Object? mediaRaw) {
    if (mediaRaw is! Map) {
      return null;
    }
    final media = Map<String, dynamic>.from(mediaRaw);

    String? pick(Object? list, List<String> keys) {
      if (list is! List) return null;
      for (final item in list) {
        if (item is! Map) continue;
        for (final key in keys) {
          final url = item[key];
          if (url is String && url.isNotEmpty) return previewImageUrl(url);
        }
      }
      return null;
    }

    const photoKeys = ['url'];
    const thumbKeys = ['thumbnail_url', 'thumbnail', 'preview_image_url'];
    return pick(media['photos'], photoKeys) ??
        pick(media['all'], thumbKeys) ??
        pick(media['videos'], thumbKeys);
  }

  /// Prefer a smaller pbs.twimg.com variant for list previews.
  static String previewImageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.host.contains('twimg.com')) {
      return url;
    }
    final params = Map<String, String>.from(uri.queryParameters);
    params['name'] = 'small';
    return uri.replace(queryParameters: params).toString();
  }

  void clear() {
    _cache.clear();
  }
}
