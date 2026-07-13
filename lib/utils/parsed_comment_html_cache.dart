import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';

/// Cache of [HKGaldenHtmlParser.commentWithQuotes] keyed by reply/parent/blocks.
class ParsedCommentHtmlCache {
  static final ParsedCommentHtmlCache instance = ParsedCommentHtmlCache._();
  ParsedCommentHtmlCache._();

  static const int _maxEntries = 200;

  final Map<String, String> _cache = <String, String>{};
  final HKGaldenHtmlParser _parser = HKGaldenHtmlParser();

  String getOrParse(Reply reply, SessionUserState sessionState) {
    final key = _cacheKey(reply, sessionState);
    return _cache.putIfAbsent(key, () {
      while (_cache.length >= _maxEntries) {
        _cache.remove(_cache.keys.first);
      }
      return _parser.commentWithQuotes(reply, sessionState) ?? '';
    });
  }

  void prewarm(Iterable<Reply> replies, SessionUserState sessionState) {
    for (final reply in replies) {
      getOrParse(reply, sessionState);
    }
  }

  void clear() {
    _cache.clear();
  }

  String _cacheKey(Reply reply, SessionUserState sessionState) {
    final buffer = StringBuffer()
      ..write(reply.replyId ?? '')
      ..write('\u0001')
      ..write(reply.content ?? '')
      ..write('\u0001');

    Reply? parent = reply.parent;
    var depth = 0;
    while (parent != null && depth < 3) {
      buffer
        ..write(parent.replyId ?? '')
        ..write('\u0002')
        ..write(parent.content ?? '')
        ..write('\u0002')
        ..write(parent.authorNickname)
        ..write('\u0002')
        ..write(parent.author.userId)
        ..write('\u0001');
      parent = parent.parent;
      depth++;
    }

    buffer.write(sessionState.runtimeType);
    if (sessionState is SessionUserLoaded) {
      buffer.write('\u0001');
      final blocked = List<String>.of(sessionState.sessionUser.blockedUsers)
        ..sort();
      buffer.write(blocked.join(','));
    }
    return buffer.toString();
  }
}
