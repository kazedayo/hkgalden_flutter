import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/parser/delta_json.parser.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';

void main() {
  group('DeltaJsonParser', () {
    late DeltaJsonParser parser;

    setUp(() {
      parser = DeltaJsonParser();
    });

    test('valid simple text op produces div#pmc with paragraph', () async {
      final html = await parser.toGaldenHtml([
        {'insert': 'hello\n'},
      ]);

      expect(html, startsWith('<div id="pmc">'));
      expect(html, endsWith('</div>'));
      expect(html, contains('<p>hello</p>'));
      expect(html, '<div id="pmc"><p>hello</p></div>');
    });

    test('empty list returns empty pmc div structure', () async {
      final html = await parser.toGaldenHtml([]);

      expect(html, '<div id="pmc"></div>');
    });

    test('multi-line insert with newlines creates multiple p tags', () async {
      final html = await parser.toGaldenHtml([
        {'insert': 'line1\nline2\nline3\n'},
      ]);

      expect(html, startsWith('<div id="pmc">'));
      expect(html, endsWith('</div>'));
      expect(html, contains('<p>line1</p>'));
      expect(html, contains('<p>line2</p>'));
      expect(html, contains('<p>line3</p>'));
      expect(html, '<div id="pmc"><p>line1</p><p>line2</p><p>line3</p></div>');
      expect('<p>'.allMatches(html).length, 3);
    });

    test('list containing a non-map element is skipped without throwing',
        () async {
      final html = await parser.toGaldenHtml([
        'not a map',
        42,
        null,
        {'insert': 'ok\n'},
      ]);

      expect(html, '<div id="pmc"><p>ok</p></div>');
    });

    test('op with invalid attributes type does not throw', () async {
      final html = await parser.toGaldenHtml([
        {'insert': 'text\n', 'attributes': 'invalid'},
      ]);

      expect(html, '<div id="pmc"><p>text</p></div>');
    });

    test('text containing < and & is escaped in output', () async {
      final html = await parser.toGaldenHtml([
        {'insert': 'a < b & c\n'},
      ]);

      expect(html, '<div id="pmc"><p>a &lt; b &amp; c</p></div>');
      expect(html, isNot(contains('<script>')));
      expect(html, isNot(contains('a < b')));
    });

    test('link href containing " is escaped in attribute', () async {
      final html = await parser.toGaldenHtml([
        {
          'insert': 'click',
          'attributes': {'a': 'https://example.com/"onclick="alert(1)'},
        },
        {'insert': '\n'},
      ]);

      expect(
        html,
        contains(
          'data-href="https://example.com/&quot;onclick=&quot;alert(1)"',
        ),
      );
      expect(html, contains('>click</span>'));
      expect(html, isNot(contains('data-href="https://example.com/"onclick=')));
    });

    test(
      'invalid image URL still produces img with default sx/sy and does not hang',
      () async {
        final failingParser = DeltaJsonParser(
          imageSizeResolver: (url) => Future<({int width, int height})>.error(
            StateError('failed to load $url'),
          ),
        );

        const source = 'https://invalid.invalid/nope.png';
        final html = await failingParser.toGaldenHtml([
          _imageEmbedOp(source),
          {'insert': '\n'},
        ]);

        expect(html, contains('data-nodetype="img"'));
        expect(html, contains('data-src="$source"'));
        expect(
          html,
          contains('data-sx="${DeltaJsonParser.defaultImageWidth}"'),
        );
        expect(
          html,
          contains('data-sy="${DeltaJsonParser.defaultImageHeight}"'),
        );
        expect(html, matches(RegExp(r'data-sx="\d+"')));
        expect(html, matches(RegExp(r'data-sy="\d+"')));
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    test(
      'image size resolver timeout yields default dimensions',
      () async {
        final slowParser = DeltaJsonParser(
          imageSizeResolver: (url) async {
            await Future<void>.delayed(const Duration(seconds: 30));
            return (width: 100, height: 100);
          },
        );

        final html = await slowParser.toGaldenHtml([
          _imageEmbedOp('https://example.com/slow.png'),
          {'insert': '\n'},
        ]);

        expect(html, contains('data-nodetype="img"'));
        expect(html, contains('data-src="https://example.com/slow.png"'));
        expect(
          html,
          contains('data-sx="${DeltaJsonParser.defaultImageWidth}"'),
        );
        expect(
          html,
          contains('data-sy="${DeltaJsonParser.defaultImageHeight}"'),
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );

    test('image size resolver success path uses resolved dimensions', () async {
      final sizedParser = DeltaJsonParser(
        imageSizeResolver: (url) async => (width: 320, height: 240),
      );

      final html = await sizedParser.toGaldenHtml([
        _imageEmbedOp('https://example.com/photo.png'),
        {'insert': '\n'},
      ]);

      expect(html, contains('data-nodetype="img"'));
      expect(html, contains('data-src="https://example.com/photo.png"'));
      expect(html, contains('data-sx="320"'));
      expect(html, contains('data-sy="240"'));
    });

    test('image src with " is escaped in data-src attribute', () async {
      final sizedParser = DeltaJsonParser(
        imageSizeResolver: (url) async => (width: 1, height: 1),
      );

      final html = await sizedParser.toGaldenHtml([
        _imageEmbedOp('https://example.com/"onerror="alert(1)'),
        {'insert': '\n'},
      ]);

      expect(
        html,
        contains('data-src="https://example.com/&quot;onerror=&quot;alert(1)"'),
      );
      expect(html, isNot(contains('data-src="https://example.com/"onerror=')));
    });

    test(
      'bold+color attributes yield identical HTML regardless of map key order',
      () async {
        final attrsBoldFirst = <String, dynamic>{
          'b': true,
          'color': '#ff0000',
        };
        final attrsColorFirst = <String, dynamic>{
          'color': '#ff0000',
          'b': true,
        };

        final htmlBoldFirst = await parser.toGaldenHtml([
          {'insert': 'hi', 'attributes': attrsBoldFirst},
          {'insert': '\n'},
        ]);
        final htmlColorFirst = await parser.toGaldenHtml([
          {'insert': 'hi', 'attributes': attrsColorFirst},
          {'insert': '\n'},
        ]);

        expect(htmlBoldFirst, htmlColorFirst);
        expect(
          htmlBoldFirst,
          '<div id="pmc"><p>'
          '<span data-nodetype="color" data-value="#ff0000">'
          '<span data-nodetype="b">hi</span>'
          '</span>'
          '</p></div>',
        );
      },
    );

    test('a + b + color produce fixed outer→inner nesting', () async {
      final html = await parser.toGaldenHtml([
        {
          'insert': 'x',
          'attributes': <String, dynamic>{
            'b': true,
            'a': 'https://example.com',
            'color': '#00ff00',
          },
        },
        {'insert': '\n'},
      ]);

      expect(
        html,
        '<div id="pmc"><p>'
        '<span data-nodetype="a" data-href="https://example.com">'
        '<span data-nodetype="color" data-value="#00ff00">'
        '<span data-nodetype="b">x</span>'
        '</span>'
        '</span>'
        '</p></div>',
      );
    });

    test('unknown attribute keys are ignored', () async {
      final html = await parser.toGaldenHtml([
        {
          'insert': 'plain',
          'attributes': <String, dynamic>{
            'unknownStyle': true,
            'notARealKey': 'whatever',
            'b': true,
          },
        },
        {'insert': '\n'},
      ]);

      expect(
        html,
        '<div id="pmc"><p>'
        '<span data-nodetype="b">plain</span>'
        '</p></div>',
      );
      expect(html, isNot(contains('unknownStyle')));
      expect(html, isNot(contains('notARealKey')));
    });

    test(
      'smiley embed with id and packId produces smiley span with those attrs',
      () async {
        final html = await parser.toGaldenHtml([
          {
            'insert': ' ',
            'attributes': {
              'embed': {
                'type': 'smiley',
                'id': 'A7WUrp9FZ62',
                'packId': 'hkg',
                'sx': 21,
                'sy': 17,
                'alt': '[sosad]',
              },
            },
          },
          {'insert': '\n'},
        ]);

        expect(html, contains('data-nodetype="smiley"'));
        expect(html, contains('data-id="A7WUrp9FZ62"'));
        expect(html, contains('data-pack-id="hkg"'));
        expect(html, contains('data-sx="21"'));
        expect(html, contains('data-sy="17"'));
        expect(html, contains('data-alt="[sosad]"'));
        expect(
          html,
          contains(
            '<span data-nodetype="smiley" data-id="A7WUrp9FZ62" '
            'data-pack-id="hkg" data-sx="21" data-sy="17" '
            'data-alt="[sosad]"></span>',
          ),
        );
      },
    );

    test(
      'quill-native smiley insert {smiley:{...}} with width/height maps to sx/sy',
      () async {
        final html = await parser.toGaldenHtml([
          {
            'insert': {
              'smiley': {
                'id': 'A7WUrp9FZ62',
                'packId': 'hkg',
                'width': 21,
                'height': 17,
                'alt': '[sosad]',
              },
            },
          },
          {'insert': '\n'},
        ]);

        expect(html, contains('data-nodetype="smiley"'));
        expect(html, contains('data-id="A7WUrp9FZ62"'));
        expect(html, contains('data-pack-id="hkg"'));
        expect(html, contains('data-sx="21"'));
        expect(html, contains('data-sy="17"'));
        expect(html, contains('data-alt="[sosad]"'));
      },
    );

    test(
      'quill-native image insert {image:url} produces img span',
      () async {
        final sizedParser = DeltaJsonParser(
          imageSizeResolver: (url) async => (width: 640, height: 480),
        );
        final html = await sizedParser.toGaldenHtml([
          {
            'insert': {'image': 'https://cdn.example.com/a.png'},
          },
          {'insert': '\n'},
        ]);

        expect(html, contains('data-nodetype="img"'));
        expect(html, contains('data-src="https://cdn.example.com/a.png"'));
        expect(html, contains('data-sx="640"'));
        expect(html, contains('data-sy="480"'));
      },
    );

    test(
      'smiley embed missing packId does not throw and does not emit incomplete smiley',
      () async {
        final html = await parser.toGaldenHtml([
          {
            'insert': ' ',
            'attributes': {
              'embed': {
                'type': 'smiley',
                'id': 'A7WUrp9FZ62',
                'sx': 21,
                'sy': 17,
              },
            },
          },
          {'insert': '\n'},
        ]);

        expect(html, isNot(contains('data-nodetype="smiley"')));
        expect(html, isNot(contains('data-pack-id=')));
        expect(html, isNot(contains('data-id="A7WUrp9FZ62"')));
        expect(html, '<div id="pmc"><p> </p></div>');
      },
    );

    test(
      'round-trip: bold delta through DeltaJsonParser then HKGaldenHtmlParser yields <b>',
      () async {
        final galdenHtml = await parser.toGaldenHtml([
          {
            'insert': 'bold text',
            'attributes': {'b': true},
          },
          {'insert': '\n'},
        ]);

        expect(
          galdenHtml,
          '<div id="pmc"><p><span data-nodetype="b">bold text</span></p></div>',
        );

        final rendered = HKGaldenHtmlParser().parse(galdenHtml);
        expect(rendered, isNotNull);
        expect(rendered, contains('<b>'));
        expect(rendered, contains('</b>'));
        expect(rendered, contains('bold text'));
        expect(rendered, isNot(contains('data-nodetype')));
      },
    );
  });
}

Map<String, dynamic> _imageEmbedOp(String source) {
  return {
    'insert': ' ',
    'attributes': {
      'embed': {
        'type': 'image',
        'source': source,
      },
    },
  };
}
