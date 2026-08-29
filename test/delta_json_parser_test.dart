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

