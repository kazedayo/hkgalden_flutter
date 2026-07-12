import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';

/// Caches [HKGaldenHtmlParser.commentWithQuotes] results for thread comment
/// cells so scrolling / rebuilds do not re-walk quote chains.
///
/// Key includes reply identity, parent-chain identity (quotes), and the session
/// blocked-user set (quote filtering depends on it).
class ParsedCommentHtmlCache {
  static final ParsedCommentHtmlCache instance = ParsedCommentHtmlCache._();
  ParsedCommentHtmlCache._();

  static const int _maxEntries = 200;

  /// Insertion-ordered map for simple FIFO eviction.
  final Map<String, String> _cache = <String, String>{};
  final HKGaldenHtmlParser _parser = HKGaldenHtmlParser();

  String getOrParse(Reply reply, SessionUserState sessionState) {
    final key = _cacheKey(reply, sessionState);
    return _cache.putIfAbsent(key, () {
      // Evict oldest entries before inserting a new one.
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

  /// Builds a cache key from reply body, parent chain (up to 3 parents, matching
  /// [HKGaldenHtmlParser] maxDepth), and blocked-user set identity.
  String _cacheKey(Reply reply, SessionUserState sessionState) {
    final buffer = StringBuffer()
      ..write(reply.replyId ?? '')
      ..write('\u0001')
      ..write(reply.content ?? '')
      ..write('\u0001');

    // Parent chain identity: quotes walk up to maxDepth = 3 parents.
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

    // Session type affects quote behavior (Loaded vs Undefined vs Loading).
    buffer.write(sessionState.runtimeType);
    if (sessionState is SessionUserLoaded) {
      buffer.write('\u0001');
      // Order-independent blocked-set identity.
      final blocked = List<String>.of(sessionState.sessionUser.blockedUsers)
        ..sort();
      buffer.write(blocked.join(','));
    }
    return buffer.toString();
  }
}
