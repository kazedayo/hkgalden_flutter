import 'dart:convert';

import 'package:hkgalden_flutter/utils/youtube_oembed_cache.dart';
import 'package:hkgalden_flutter/utils/youtube_url.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('YoutubeUrl.tryParseVideoId', () {
    test('parses common watch / short / embed forms', () {
      expect(
        YoutubeUrl.tryParseVideoId(
          'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        ),
        'dQw4w9WgXcQ',
      );
      expect(
        YoutubeUrl.tryParseVideoId('https://youtu.be/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        YoutubeUrl.tryParseVideoId(
          'https://www.youtube.com/embed/dQw4w9WgXcQ',
        ),
        'dQw4w9WgXcQ',
      );
      expect(
        YoutubeUrl.tryParseVideoId(
          'https://www.youtube.com/shorts/dQw4w9WgXcQ',
        ),
        'dQw4w9WgXcQ',
      );
      expect(
        YoutubeUrl.tryParseVideoId(
          'https://m.youtube.com/watch?v=dQw4w9WgXcQ&feature=share',
        ),
        'dQw4w9WgXcQ',
      );
      expect(
        YoutubeUrl.tryParseVideoId(
          'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ',
        ),
        'dQw4w9WgXcQ',
      );
    });

    test('rejects non-youtube and invalid ids', () {
      expect(YoutubeUrl.tryParseVideoId(null), isNull);
      expect(YoutubeUrl.tryParseVideoId(''), isNull);
      expect(
        YoutubeUrl.tryParseVideoId('https://example.com/watch?v=dQw4w9WgXcQ'),
        isNull,
      );
      expect(
        YoutubeUrl.tryParseVideoId('https://www.youtube.com/watch?v=short'),
        isNull,
      );
      expect(
        YoutubeUrl.tryParseVideoId('https://www.youtube.com/channel/abc'),
        isNull,
      );
    });

    test('thumbnail and watch helpers', () {
      expect(
        YoutubeUrl.thumbnailUrl('dQw4w9WgXcQ'),
        'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      );
      expect(
        YoutubeUrl.watchUrl('dQw4w9WgXcQ'),
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );
    });
  });

  group('YoutubeOEmbedCache', () {
    test('parses oEmbed JSON and caches result', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        expect(request.url.host, 'www.youtube.com');
        expect(request.url.path, '/oembed');
        return http.Response(
          jsonEncode({
            'title': 'Never Gonna Give You Up',
            'author_name': 'Rick Astley',
            'thumbnail_url': 'https://example.com/t.jpg',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final cache = YoutubeOEmbedCache.forTesting(client);

      final first = await cache.fetch('dQw4w9WgXcQ');
      final second = await cache.fetch('dQw4w9WgXcQ');

      expect(first?.title, 'Never Gonna Give You Up');
      expect(first?.authorName, 'Rick Astley');
      expect(second?.title, first?.title);
      expect(calls, 1);
    });

    test('returns null on non-200', () async {
      final client = MockClient((request) async {
        return http.Response('not found', 404);
      });
      final cache = YoutubeOEmbedCache.forTesting(client);
      expect(await cache.fetch('dQw4w9WgXcQ'), isNull);
    });
  });
}
