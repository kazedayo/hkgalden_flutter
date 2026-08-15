import 'dart:collection';

import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';

/// Parsed comment HTML cache keyed by reply/parent/blocks.
class ParsedCommentHtmlCache {
  static final ParsedCommentHtmlCache instance = ParsedCommentHtmlCache._();
  ParsedCommentHtmlCache._();

  static const int _maxEntries = 200;

  final LinkedHashMap<String, String> _cache = LinkedHashMap<String, String>();
  final HKGaldenHtmlParser _parser = HKGaldenHtmlParser();

  String getOrParse(Reply reply, SessionUserState sessionState) {
    final key = _cacheKey(reply, sessionState);
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached;
      return cached;
    }
    while (_cache.length >= _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    final parsed = _parser.commentWithQuotes(reply, sessionState) ?? '';
    _cache[key] = parsed;
    return parsed;
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
      ..write(_replyIdentity(reply))
      ..write('\u0001');

    Reply? parent = reply.parent;
    var depth = 0;
    while (parent != null && depth < 3) {
      buffer
        ..write(_replyIdentity(parent))
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
      buffer.write(
        _blockedUsersFingerprint(sessionState.sessionUser.blockedUsers),
      );
    }
    return buffer.toString();
  }

  /// Prefer [Reply.replyId]. Without an id, fingerprint content by length +
  /// [String.hashCode]. Distinct HTML can collide and reuse a parse; ids are
  /// the normal case.
  String _replyIdentity(Reply reply) {
    final id = reply.replyId;
    if (id != null && id.isNotEmpty) {
      return id;
    }
    final content = reply.content ?? '';
    return '${content.length}:${content.hashCode}';
  }

  int _blockedUsersFingerprint(List<String> blockedUsers) {
    final blocked = List<String>.of(blockedUsers)..sort();
    return blocked.join(',').hashCode;
  }
}
