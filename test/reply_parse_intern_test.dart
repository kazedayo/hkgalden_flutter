import 'dart:collection';

import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:test/test.dart';

class _WriteCountingMap extends MapBase<String, String> {
  final Map<String, String> _inner = {};
  int writes = 0;

  @override
  String? operator [](Object? key) => _inner[key];

  @override
  void operator []=(String key, String value) {
    writes++;
    _inner[key] = value;
  }

  @override
  void clear() => _inner.clear();

  @override
  Iterable<String> get keys => _inner.keys;

  @override
  String? remove(Object? key) => _inner.remove(key);
}

Map<String, dynamic> _authorJson() => {
      'id': 'u1',
      'nickname': 'nick',
      'avatar': '',
      'groups': <dynamic>[],
    };

Map<String, dynamic> _replyJson({
  required String id,
  required int floor,
  required String content,
  Map<String, dynamic>? parent,
}) =>
    {
      'id': id,
      'floor': floor,
      'author': _authorJson(),
      'authorNickname': 'nick',
      'content': content,
      'date': '2024-01-01T00:00:00.000Z',
      'parent': parent,
    };

void main() {
  const rawHtml =
      '<p>hello<span data-nodetype="smiley" data-id="A7WUrp9FZ62" data-pack-id="hkg"></span></p>';
  const parsedHtml =
      '<p>hello<icon src="https://s.hkgalden.org/smilies/hkg/A7WUrp9FZ62.gif"></icon></p>';

  test('shared parent id is parsed once when intern is reused', () {
    final intern = _WriteCountingMap();
    final parent = _replyJson(id: 'p1', floor: 1, content: rawHtml);
    final first = Reply.fromJson(
      _replyJson(id: 'c1', floor: 2, content: rawHtml, parent: parent),
      intern,
    );
    final second = Reply.fromJson(
      _replyJson(id: 'c2', floor: 3, content: rawHtml, parent: parent),
      intern,
    );

    expect(first.parent!.content, parsedHtml);
    expect(second.parent!.content, parsedHtml);
    expect(intern['p1'], parsedHtml);
    expect(intern.writes, 3);
  });

  test('Thread.fromJson interns parent content across replies', () {
    final parent = _replyJson(id: 'p1', floor: 1, content: rawHtml);
    final thread = Thread.fromJson({
      'id': 1,
      'title': 't',
      'status': 'active',
      'totalReplies': 2,
      'tags': [
        {'name': 'tag', 'color': 'FF0000'}
      ],
      'replies': [
        _replyJson(id: 'c1', floor: 2, content: rawHtml, parent: parent),
        _replyJson(id: 'c2', floor: 3, content: rawHtml, parent: parent),
      ],
    });

    expect(thread.replies, hasLength(2));
    expect(thread.replies[0].parent!.content, parsedHtml);
    expect(thread.replies[1].parent!.content, parsedHtml);
    expect(thread.replies[0].content, parsedHtml);
  });

  test('replyFromJson still parses a nested reply tree', () {
    final reply = replyFromJson(
      _replyJson(
        id: 'c1',
        floor: 2,
        content: rawHtml,
        parent: _replyJson(id: 'p1', floor: 1, content: rawHtml),
      ),
    );

    expect(reply.replyId, 'c1');
    expect(reply.content, parsedHtml);
    expect(reply.parent!.replyId, 'p1');
    expect(reply.parent!.content, parsedHtml);
  });
}
