import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';
import 'package:test/test.dart';

User _user(String id, {String nick = 'nick', List<String> blocked = const []}) {
  return User(
    userId: id,
    nickName: nick,
    avatar: '',
    userGroup: const [],
    blockedUsers: blocked,
  );
}

Reply _reply({
  required int floor,
  required String authorId,
  required String nickname,
  required String content,
  Reply? parent,
}) {
  return Reply(
    floor: floor,
    content: content,
    author: _user(authorId, nick: nickname),
    authorNickname: nickname,
    date: DateTime.utc(2024, 1, 1),
    parent: parent,
  );
}

void main() {
  group('hkGalden parser', () {
    late HKGaldenHtmlParser parser;
    setUp(() {
      parser = HKGaldenHtmlParser();
    });
    test('parse icon', () {
      const String html =
          '<div><p>我係用緊廿幾蚊隻嗰啲滑鼠同keyboard<span data-nodetype="smiley" data-id="A7WUrp9FZ62" data-pack-id="hkg" data-sx="21" data-sy="17" data-alt="[sosad]"></span><span data-nodetype="smiley" data-id="A7WUrp9FZ62" data-pack-id="hkg" data-sx="21" data-sy="17" data-alt="[sosad]"></span><span data-nodetype="smiley" data-id="A7WUrp9FZ62" data-pack-id="hkg" data-sx="21" data-sy="17" data-alt="[sosad]"></span></p></div>';
      final String? output = parser.parse(html);
      expect(
          output,
          '<div><p>我係用緊廿幾蚊隻嗰啲滑鼠同keyboard<icon src="https://s.hkgalden.org/smilies/hkg/A7WUrp9FZ62.gif"></icon><icon src="https://s.hkgalden.org/smilies/hkg/A7WUrp9FZ62.gif"></icon><icon src="https://s.hkgalden.org/smilies/hkg/A7WUrp9FZ62.gif"></icon></p></div>');
    });

    test('missing data-src does not throw', () {
      const String html = '<div><span data-nodetype="img"></span></div>';
      final String? output = parser.parse(html);
      expect(output, isNotNull);
      // Original span kept when data-src is missing
      expect(output, contains('data-nodetype="img"'));
    });

    test('p data-nodetype center maps to class center', () {
      const String html = '<p data-nodetype="center">hello</p>';
      final String? output = parser.parse(html);
      expect(output, isNotNull);
      expect(output, contains('hello'));
      expect(
        output!.contains('class="center"') || output.contains('class=center'),
        isTrue,
      );
      expect(output, isNot(contains('data-nodetype')));
    });

    test('p data-nodetype right maps to class right', () {
      const String html = '<p data-nodetype="right">hello</p>';
      final String? output = parser.parse(html);
      expect(output, isNotNull);
      expect(output, contains('hello'));
      expect(
        output!.contains('class="right"') || output.contains('class=right'),
        isTrue,
      );
      expect(output, isNot(contains('data-nodetype')));
    });

    test('nested color wrapping bold keeps both and text', () {
      const String html =
          '<span data-nodetype="color" data-value="#ff0000"><span data-nodetype="b">x</span></span>';
      final String? output = parser.parse(html);
      expect(output, isNotNull);
      expect(output, contains('x'));
      expect(
        output!.contains('class="color"') || output.contains('class=color'),
        isTrue,
      );
      expect(
        output.contains('hex="#ff0000"') || output.contains('hex=#ff0000'),
        isTrue,
      );
      expect(output, contains('<b>'));
      expect(output, contains('</b>'));
      expect(output, isNot(contains('data-nodetype')));
    });

    test('missing data-href on link span does not throw; content retained', () {
      const String html =
          '<div><span data-nodetype="a">click me</span></div>';
      String? output;
      expect(() => output = parser.parse(html), returnsNormally);
      expect(output, isNotNull);
      expect(output, contains('click me'));
      // Original span kept when data-href is missing
      expect(output, contains('data-nodetype="a"'));
      expect(output, isNot(contains('<a ')));
      expect(output, isNot(contains('<a>')));
    });

    test('missing data-value on color span does not throw', () {
      const String html =
          '<div><span data-nodetype="color">colored?</span></div>';
      String? output;
      expect(() => output = parser.parse(html), returnsNormally);
      expect(output, isNotNull);
      expect(output, contains('colored?'));
      // Original span kept when data-value is missing
      expect(output, contains('data-nodetype="color"'));
      expect(output, isNot(contains('class="color"')));
      expect(output, isNot(contains('hex=')));
    });

    test('missing smiley pack-id does not throw', () {
      const String html =
          '<div><span data-nodetype="smiley" data-id="A7WUrp9FZ62" data-sx="21" data-sy="17" data-alt="[sosad]"></span></div>';
      String? output;
      expect(() => output = parser.parse(html), returnsNormally);
      expect(output, isNotNull);
      // Incomplete smiley must not become an icon tag
      expect(output, isNot(contains('<icon')));
      expect(output, contains('data-nodetype="smiley"'));
      expect(output, contains('data-id="A7WUrp9FZ62"'));
    });

    test('empty string parse does not throw', () {
      String? output;
      expect(() => output = parser.parse(''), returnsNormally);
      // Non-crashing result: null is fine only if not thrown; prefer empty-ish
      expect(output, isNotNull);
      expect(output, isA<String>());
    });

    test('malformed HTML still returns a string', () {
      // Broken nesting / unclosed tags should not crash the parser.
      const String html =
          '<div><span data-nodetype="b"><i>unclosed and <<<<weird';
      String? output;
      expect(() => output = parser.parse(html), returnsNormally);
      expect(output, isNotNull);
      expect(output, isA<String>());
    });

    test('nested b+i+u styles work in single pass', () {
      const String html =
          '<span data-nodetype="b"><span data-nodetype="i"><span data-nodetype="u">styled</span></span></span>';
      final String? output = parser.parse(html);
      expect(output, isNotNull);
      expect(output, contains('styled'));
      expect(output, contains('<b>'));
      expect(output, contains('</b>'));
      expect(output, contains('<i>'));
      expect(output, contains('</i>'));
      expect(output, contains('<u>'));
      expect(output, contains('</u>'));
      expect(output, isNot(contains('data-nodetype')));
      // Nested order preserved: b wraps i wraps u
      expect(
        output,
        contains('<b><i><u>styled</u></i></b>'),
      );
    });

    test('image with valid data-src becomes img src', () {
      const String html =
          '<div><span data-nodetype="img" data-src="https://example.com/photo.png" data-sx="100" data-sy="80"></span></div>';
      final String? output = parser.parse(html);
      expect(output, isNotNull);
      expect(output, contains('<img'));
      expect(
        output!.contains('src="https://example.com/photo.png"') ||
            output.contains("src=https://example.com/photo.png"),
        isTrue,
      );
      expect(output, isNot(contains('data-nodetype="img"')));
      expect(output, isNot(contains('data-src=')));
      // Pixel size preserved for thread layout reservation.
      expect(output, contains('data-sx="100"'));
      expect(output, contains('data-sy="80"'));
    });
  });

  group('commentWithQuotes', () {
    late HKGaldenHtmlParser parser;
    setUp(() {
      parser = HKGaldenHtmlParser();
    });

    test('single-level quote includes quoteName and blockquote', () {
      final parent = _reply(
        floor: 1,
        authorId: 'p1',
        nickname: 'ParentNick',
        content: '<p>parent body</p>',
      );
      final reply = _reply(
        floor: 2,
        authorId: 'r1',
        nickname: 'ReplyNick',
        content: '<p>reply body</p>',
        parent: parent,
      );

      final result = parser.commentWithQuotes(reply, SessionUserUndefined());

      expect(result, isNotNull);
      expect(result, contains('<blockquote>'));
      expect(result, contains('class="quoteName"'));
      expect(result, contains('ParentNick 說:'));
      expect(result, contains('parent body'));
      expect(result, contains('reply body'));
      expect(result, isNot(contains('<blockquote style')));
    });

    test('blocked user parent is skipped when SessionUserLoaded', () {
      final parent = _reply(
        floor: 1,
        authorId: 'blocked-user',
        nickname: 'BlockedNick',
        content: '<p>blocked parent</p>',
      );
      final reply = _reply(
        floor: 2,
        authorId: 'r1',
        nickname: 'ReplyNick',
        content: '<p>reply body</p>',
        parent: parent,
      );

      final state = SessionUserLoaded(
        sessionUser: _user('me', blocked: ['blocked-user']),
      );

      final result = parser.commentWithQuotes(reply, state);

      expect(result, isNotNull);
      expect(result, isNot(contains('BlockedNick')));
      expect(result, isNot(contains('blocked parent')));
      expect(result, isNot(contains('<blockquote>')));
      expect(result, contains('reply body'));
    });

    test('depth limit: chain of 4 parents only includes 3 blockquotes max', () {
      final p4 = _reply(
        floor: 1,
        authorId: 'a4',
        nickname: 'Nick4',
        content: '<p>content4</p>',
      );
      final p3 = _reply(
        floor: 2,
        authorId: 'a3',
        nickname: 'Nick3',
        content: '<p>content3</p>',
        parent: p4,
      );
      final p2 = _reply(
        floor: 3,
        authorId: 'a2',
        nickname: 'Nick2',
        content: '<p>content2</p>',
        parent: p3,
      );
      final p1 = _reply(
        floor: 4,
        authorId: 'a1',
        nickname: 'Nick1',
        content: '<p>content1</p>',
        parent: p2,
      );
      final reply = _reply(
        floor: 5,
        authorId: 'r1',
        nickname: 'ReplyNick',
        content: '<p>reply body</p>',
        parent: p1,
      );

      final result =
          parser.commentWithQuotes(reply, SessionUserUndefined());

      expect(result, isNotNull);
      final blockquoteCount = '<blockquote>'.allMatches(result!).length;
      expect(blockquoteCount, 3);
      // Closest three parents included
      expect(result, contains('Nick1 說:'));
      expect(result, contains('Nick2 說:'));
      expect(result, contains('Nick3 說:'));
      // Fourth parent beyond maxDepth excluded
      expect(result, isNot(contains('Nick4 說:')));
      expect(result, isNot(contains('content4')));
      expect(result, contains('reply body'));
    });
  });
}
