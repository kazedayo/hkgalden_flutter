import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:hkgalden_flutter/utils/inflight_cache.dart';
import 'package:hkgalden_flutter/utils/youtube_url.dart';

class YoutubeOEmbedInfo {
  final String title;
  final String? authorName;
  final String? thumbnailUrl;

  const YoutubeOEmbedInfo({
    required this.title,
    this.authorName,
    this.thumbnailUrl,
  });
}

/// In-memory oEmbed title cache (avoids re-fetch on list rebuild).
class YoutubeOEmbedCache {
  YoutubeOEmbedCache._({http.Client? client}) : _client = client ?? http.Client();

  static final YoutubeOEmbedCache instance = YoutubeOEmbedCache._();

  final http.Client _client;
  final InflightCache<String, YoutubeOEmbedInfo?> _cache = InflightCache();

  factory YoutubeOEmbedCache.forTesting(http.Client client) {
    return YoutubeOEmbedCache._(client: client);
  }

  Future<YoutubeOEmbedInfo?> fetch(String videoId) {
    return _cache.get(videoId, () => _load(videoId));
  }

  Future<YoutubeOEmbedInfo?> _load(String videoId) async {
    final uri = Uri.https('www.youtube.com', '/oembed', {
      'url': YoutubeUrl.watchUrl(videoId),
      'format': 'json',
    });
    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        return null;
      }
      final title = decoded['title'];
      if (title is! String || title.isEmpty) {
        return null;
      }
      return YoutubeOEmbedInfo(
        title: title,
        authorName: decoded['author_name'] is String
            ? decoded['author_name'] as String
            : null,
        thumbnailUrl: decoded['thumbnail_url'] is String
            ? decoded['thumbnail_url'] as String
            : null,
      );
    } catch (_) {
      return null;
    }
  }

  void clear() {
    _cache.clear();
  }
}
