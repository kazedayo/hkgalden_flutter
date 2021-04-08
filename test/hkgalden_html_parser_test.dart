import 'package:test/test.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';

void main() {
  group("hkGalden parser", () {
    late HKGaldenHtmlParser parser;
    setUp(() {
      parser = HKGaldenHtmlParser();
    });
    test('parse icon', () {
      const String html =
          '<div><p>我係用緊廿幾蚊隻嗰啲滑鼠同keyboard<span data-nodetype="smiley" data-id="A7WUrp9FZ62" data-pack-id="hkg" data-sx="21" data-sy="17" data-alt="[sosad]"></span><span data-nodetype="smiley" data-id="A7WUrp9FZ62" data-pack-id="hkg" data-sx="21" data-sy="17" data-alt="[sosad]"></span><span data-nodetype="smiley" data-id="A7WUrp9FZ62" data-pack-id="hkg" data-sx="21" data-sy="17" data-alt="[sosad]"></span></p></div>';
      final String? output = parser.parse(html);
      expect(output,
          '<div><p>我係用緊廿幾蚊隻嗰啲滑鼠同keyboard<icon src="https://s.hkgalden.org/smilies/hkg/A7WUrp9FZ62.gif"></icon><icon src="https://s.hkgalden.org/smilies/hkg/A7WUrp9FZ62.gif"></icon><icon src="https://s.hkgalden.org/smilies/hkg/A7WUrp9FZ62.gif"></icon></p></div>');
    });
  });
}
