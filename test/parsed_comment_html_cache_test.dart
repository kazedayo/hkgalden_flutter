import 'package:hkgalden_flutter/bloc/session_user/session_user_cubit.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/utils/parsed_comment_html_cache.dart';
import 'package:flutter_test/flutter_test.dart';

User _user(String id, {String nick = 'nick', List<String> blocked = const []}) {
  return User(
    userId: id,
    nickName: nick,
    avatar: '',
    blockedUsers: blocked,
  );
}

Reply _reply({
  String? replyId,
  required int floor,
  required String authorId,
  required String nickname,
  required String content,
  Reply? parent,
}) {
  return Reply(
    replyId: replyId,
    floor: floor,
    content: content,
    author: _user(authorId, nick: nickname),
    authorNickname: nickname,
    date: DateTime.utc(2024, 1, 1),
    parent: parent,
  );
}

void main() {
  late ParsedCommentHtmlCache cache;

  setUp(() {
    cache = ParsedCommentHtmlCache.instance;
    cache.clear();
  });

  tearDown(() {
    cache.clear();
  });

  group('ParsedCommentHtmlCache', () {
    test('same replyId + parents + blocked set reuses one parse', () {
      final parent = _reply(
        replyId: 'p1',
        floor: 1,
        authorId: 'p1',
        nickname: 'ParentNick',
        content: '<p>parent body</p>',
      );
      final reply = _reply(
        replyId: 'r1',
        floor: 2,
        authorId: 'r1',
        nickname: 'ReplyNick',
        content: '<p>reply body</p>',
        parent: parent,
      );
      final state = SessionUserLoaded(
        sessionUser: _user('me', blocked: ['x', 'y']),
      );

      final first = cache.getOrParse(reply, state);
      final second = cache.getOrParse(
        _reply(
          replyId: 'r1',
          floor: 2,
          authorId: 'r1',
          nickname: 'ReplyNick',
          content: '<p>reply body</p>',
          parent: _reply(
            replyId: 'p1',
            floor: 1,
            authorId: 'p1',
            nickname: 'ParentNick',
            content: '<p>parent body</p>',
          ),
        ),
        SessionUserLoaded(sessionUser: _user('me', blocked: ['y', 'x'])),
      );

      expect(first, contains('ParentNick 說:'));
      expect(first, contains('parent body'));
      expect(first, contains('reply body'));
      expect(identical(first, second), isTrue);
    });

    test('does not key on full HTML when reply and parent ids exist', () {
      final first = cache.getOrParse(
        _reply(
          replyId: 'r1',
          floor: 2,
          authorId: 'r1',
          nickname: 'ReplyNick',
          content: '<p>original reply</p>',
          parent: _reply(
            replyId: 'p1',
            floor: 1,
            authorId: 'p1',
            nickname: 'ParentNick',
            content: '<p>original parent</p>',
          ),
        ),
        SessionUserUndefined(),
      );
      final second = cache.getOrParse(
        _reply(
          replyId: 'r1',
          floor: 2,
          authorId: 'r1',
          nickname: 'ReplyNick',
          content: '<p>changed reply html body</p>',
          parent: _reply(
            replyId: 'p1',
            floor: 1,
            authorId: 'p1',
            nickname: 'ParentNick',
            content: '<p>changed parent html body</p>',
          ),
        ),
        SessionUserUndefined(),
      );

      expect(identical(first, second), isTrue);
      expect(second, contains('original reply'));
      expect(second, contains('original parent'));
      expect(second, isNot(contains('changed reply html body')));
      expect(second, isNot(contains('changed parent html body')));
    });

    test('different blocked user set omits blocked parent', () {
      final parent = _reply(
        replyId: 'p1',
        floor: 1,
        authorId: 'blocked-user',
        nickname: 'BlockedNick',
        content: '<p>blocked parent</p>',
      );
      final reply = _reply(
        replyId: 'r1',
        floor: 2,
        authorId: 'r1',
        nickname: 'ReplyNick',
        content: '<p>reply body</p>',
        parent: parent,
      );

      final unblocked = cache.getOrParse(
        reply,
        SessionUserLoaded(sessionUser: _user('me', blocked: [])),
      );
      final blocked = cache.getOrParse(
        reply,
        SessionUserLoaded(sessionUser: _user('me', blocked: ['blocked-user'])),
      );
      final blockedAgain = cache.getOrParse(
        reply,
        SessionUserLoaded(sessionUser: _user('me', blocked: ['blocked-user'])),
      );

      expect(unblocked, contains('BlockedNick'));
      expect(unblocked, contains('blocked parent'));
      expect(blocked, isNot(contains('BlockedNick')));
      expect(blocked, isNot(contains('blocked parent')));
      expect(blocked, contains('reply body'));
      expect(identical(unblocked, blocked), isFalse);
      expect(identical(blocked, blockedAgain), isTrue);
    });

    test('id-less replies fingerprint content so different HTML misses', () {
      final first = cache.getOrParse(
        _reply(
          floor: 1,
          authorId: 'a1',
          nickname: 'Nick',
          content: '<p>one</p>',
        ),
        SessionUserUndefined(),
      );
      final second = cache.getOrParse(
        _reply(
          floor: 1,
          authorId: 'a1',
          nickname: 'Nick',
          content: '<p>two</p>',
        ),
        SessionUserUndefined(),
      );

      expect(first, contains('one'));
      expect(second, contains('two'));
      expect(identical(first, second), isFalse);
    });

    test('parent nickname change is a different cache key', () {
      final first = cache.getOrParse(
        _reply(
          replyId: 'r1',
          floor: 2,
          authorId: 'r1',
          nickname: 'ReplyNick',
          content: '<p>reply body</p>',
          parent: _reply(
            replyId: 'p1',
            floor: 1,
            authorId: 'p1',
            nickname: 'OldNick',
            content: '<p>parent body</p>',
          ),
        ),
        SessionUserUndefined(),
      );
      final second = cache.getOrParse(
        _reply(
          replyId: 'r1',
          floor: 2,
          authorId: 'r1',
          nickname: 'ReplyNick',
          content: '<p>reply body</p>',
          parent: _reply(
            replyId: 'p1',
            floor: 1,
            authorId: 'p1',
            nickname: 'NewNick',
            content: '<p>parent body</p>',
          ),
        ),
        SessionUserUndefined(),
      );

      expect(first, contains('OldNick 說:'));
      expect(second, contains('NewNick 說:'));
      expect(identical(first, second), isFalse);
    });

    test('prewarm then getOrParse is a cache hit', () {
      final reply = _reply(
        replyId: 'r1',
        floor: 1,
        authorId: 'r1',
        nickname: 'ReplyNick',
        content: '<p>reply body</p>',
      );
      final state = SessionUserUndefined();

      cache.prewarm([reply], state);
      final first = cache.getOrParse(reply, state);
      final second = cache.getOrParse(reply, state);

      expect(first, contains('reply body'));
      expect(identical(first, second), isTrue);
    });

    test('clear drops cached values', () {
      final reply = _reply(
        replyId: 'r1',
        floor: 2,
        authorId: 'r1',
        nickname: 'ReplyNick',
        content: '<p>reply body</p>',
        parent: _reply(
          replyId: 'p1',
          floor: 1,
          authorId: 'p1',
          nickname: 'ParentNick',
          content: '<p>parent body</p>',
        ),
      );
      final state = SessionUserUndefined();

      final first = cache.getOrParse(reply, state);
      cache.clear();
      final second = cache.getOrParse(reply, state);

      expect(first, second);
      expect(identical(first, second), isFalse);
    });

    test('LRU evicts oldest unused after 200 entries', () {
      final state = SessionUserUndefined();
      final results = <String>[];
      for (var i = 0; i < 200; i++) {
        results.add(
          cache.getOrParse(
            _reply(
              replyId: 'r$i',
              floor: i,
              authorId: 'a$i',
              nickname: 'n$i',
              content: '<p>body $i</p>',
            ),
            state,
          ),
        );
      }

      final firstAgain = cache.getOrParse(
        _reply(
          replyId: 'r0',
          floor: 0,
          authorId: 'a0',
          nickname: 'n0',
          content: '<p>body 0</p>',
        ),
        state,
      );
      expect(identical(firstAgain, results[0]), isTrue);

      cache.getOrParse(
        _reply(
          replyId: 'r200',
          floor: 200,
          authorId: 'a200',
          nickname: 'n200',
          content: '<p>body 200</p>',
        ),
        state,
      );

      final evicted = cache.getOrParse(
        _reply(
          replyId: 'r1',
          floor: 1,
          authorId: 'a1',
          nickname: 'n1',
          content: '<p>body 1</p>',
        ),
        state,
      );
      expect(evicted, results[1]);
      expect(identical(evicted, results[1]), isFalse);

      final retained = cache.getOrParse(
        _reply(
          replyId: 'r0',
          floor: 0,
          authorId: 'a0',
          nickname: 'n0',
          content: '<p>body 0</p>',
        ),
        state,
      );
      expect(identical(retained, results[0]), isTrue);
    });
  });
}
