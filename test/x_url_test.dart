import 'dart:convert';

import 'package:hkgalden_flutter/utils/x_status_cache.dart';
import 'package:hkgalden_flutter/utils/x_url.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('XUrl.tryParseStatusId', () {
    test('parses common x.com / twitter.com status forms', () {
      expect(
        XUrl.tryParseStatusId(
          'https://x.com/Interior/status/463440424141459456',
        ),
        '463440424141459456',
      );
      expect(
        XUrl.tryParseStatusId(
          'https://twitter.com/Interior/status/463440424141459456',
        ),
        '463440424141459456',
      );
      expect(
        XUrl.tryParseStatusId(
          'https://mobile.twitter.com/Interior/status/463440424141459456',
        ),
        '463440424141459456',
      );
      expect(
        XUrl.tryParseStatusId(
          'https://www.x.com/Interior/status/463440424141459456?s=20',
        ),
        '463440424141459456',
      );
      expect(
        XUrl.tryParseStatusId(
          'https://x.com/i/web/status/463440424141459456',
        ),
        '463440424141459456',
      );
      expect(
        XUrl.tryParseStatusId(
          'https://x.com/i/status/463440424141459456',
        ),
        '463440424141459456',
      );
      expect(
        XUrl.tryParseStatusId(
          'http://twitter.com/foo/status/123',
        ),
        '123',
      );
    });

    test('rejects non-status and non-x urls', () {
      expect(XUrl.tryParseStatusId(null), isNull);
      expect(XUrl.tryParseStatusId(''), isNull);
      expect(
        XUrl.tryParseStatusId('https://example.com/foo/status/123'),
        isNull,
      );
      expect(
        XUrl.tryParseStatusId('https://x.com/Interior'),
        isNull,
      );
      expect(
        XUrl.tryParseStatusId('https://x.com/Interior/lists/foo'),
        isNull,
      );
      expect(
        XUrl.tryParseStatusId('https://x.com/Interior/status/notanid'),
        isNull,
      );
      expect(
        XUrl.tryParseStatusId('ftp://x.com/Interior/status/123'),
        isNull,
      );
    });
  });

  group('XStatusCache helpers', () {
    test('previewImageUrl prefers small pbs variant', () {
      expect(
        XStatusCache.previewImageUrl(
          'https://pbs.twimg.com/media/Bm54nBCCYAACwBi.jpg?name=orig',
        ),
        'https://pbs.twimg.com/media/Bm54nBCCYAACwBi.jpg?name=small',
      );
      expect(
        XStatusCache.previewImageUrl('https://example.com/a.jpg'),
        'https://example.com/a.jpg',
      );
    });

    test('firstMediaImageUrl prefers photos then video thumbnails', () {
      expect(
        XStatusCache.firstMediaImageUrl({
          'photos': [
            {
              'type': 'photo',
              'url':
                  'https://pbs.twimg.com/media/photo.jpg?name=orig',
            },
          ],
        }),
        'https://pbs.twimg.com/media/photo.jpg?name=small',
      );

      expect(
        XStatusCache.firstMediaImageUrl({
          'all': [
            {
              'type': 'video',
              'thumbnail_url': 'https://pbs.twimg.com/ext_tw_video_thumb/1.jpg',
            },
          ],
        }),
        'https://pbs.twimg.com/ext_tw_video_thumb/1.jpg?name=small',
      );

      expect(XStatusCache.firstMediaImageUrl(null), isNull);
      expect(XStatusCache.firstMediaImageUrl({}), isNull);
    });
  });

  group('XStatusCache', () {
    test('parses FxTwitter v2 JSON and caches result', () async {
      var calls = 0;
      final client = MockClient((request) async {
        calls++;
        expect(request.url.host, 'api.fxtwitter.com');
        expect(request.url.path, '/2/status/463440424141459456');
        return http.Response(
          jsonEncode({
            'code': 200,
            'status': {
              'id': '463440424141459456',
              'text':
                  "Sunsets don't get much better than this one over @GrandTetonNPS.",
              'author': {
                'name': 'US Department of the Interior',
                'screen_name': 'Interior',
                'url': 'https://x.com/Interior',
              },
              'media': {
                'photos': [
                  {
                    'type': 'photo',
                    'url':
                        'https://pbs.twimg.com/media/Bm54nBCCYAACwBi.jpg?name=orig',
                  },
                ],
                'all': [
                  {
                    'type': 'photo',
                    'url':
                        'https://pbs.twimg.com/media/Bm54nBCCYAACwBi.jpg?name=orig',
                  },
                ],
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final cache = XStatusCache.forTesting(client);

      final first = await cache.fetch('463440424141459456');
      final second = await cache.fetch('463440424141459456');

      expect(first?.authorName, 'US Department of the Interior');
      expect(first?.authorScreenName, 'Interior');
      expect(first?.authorUrl, 'https://x.com/Interior');
      expect(first?.text, contains('Sunsets'));
      expect(
        first?.imageUrl,
        'https://pbs.twimg.com/media/Bm54nBCCYAACwBi.jpg?name=small',
      );
      expect(second?.authorName, first?.authorName);
      expect(calls, 1);
    });

    test('returns null on non-200', () async {
      final client = MockClient((request) async {
        return http.Response('not found', 404);
      });
      final cache = XStatusCache.forTesting(client);
      expect(await cache.fetch('463440424141459456'), isNull);
    });

    test('returns null when status missing', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'code': 404, 'status': null}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final cache = XStatusCache.forTesting(client);
      expect(await cache.fetch('1'), isNull);
    });

    test('parses text-only status without media', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'code': 200,
            'status': {
              'text': 'Hello world',
              'author': {
                'name': 'Alice',
                'screen_name': 'alice',
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final cache = XStatusCache.forTesting(client);
      final info = await cache.fetch('99');
      expect(info?.authorName, 'Alice');
      expect(info?.text, 'Hello world');
      expect(info?.imageUrl, isNull);
    });
  });
}
