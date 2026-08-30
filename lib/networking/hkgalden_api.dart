import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:graphql/client.dart';
import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/smiley_pack.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/utils/inflight_cache.dart';
import 'package:hive/hive.dart';

class _GqlFragments {
  static const commentFields = r'''
    fragment CommentFields on Reply {
      id
      floor
      author {
        id
        avatar
        nickname
        gender
        groups {
          id
        }
      }
      authorNickname
      content
      date
    }
  ''';

  static const commentsRecursive = r'''
    fragment CommentsRecursive on Reply {
      ...CommentFields
      parent {
        ...CommentFields
        parent {
          ...CommentFields
          parent {
            ...CommentFields
          }
        }
      }
    }
  ''';

  static const threadListFields = '''
    id
    title
    status
    replies {
      author {
        id
        nickname
        avatar
        groups {
          id
        }
      }
      authorNickname
      date
      floor
    }
    totalReplies
    tags {
      name
      color
    }
  ''';

  static final getChannels = gql('''
      query GetChannels {
        channels {
          id
          name
          tags {
            name
            color
          }
        }
      }
    ''');

  static final getSessionUser = gql('''
      query GetSessionUser {
        sessionUser {
          id
          nickname
          avatar
          gender
          groups {
            id
          }
          blockedUserIds
        }
      }
    ''');

  static final getThread = gql(r'''
      query GetThreadContent($id: Int!, $page: Int!) {
        thread(id: $id,sorting: date_asc,page: $page) {
          id
          title
          status
          totalReplies
          replies {
            ...CommentsRecursive
          }
          tags {
            name
            color
          }
        }
      }
    '''
      '${_GqlFragments.commentsRecursive}'
      '${_GqlFragments.commentFields}');

  static final getThreadList = gql(r'''
      query GetThreadListQuery($channelId: String!, $page: Int!) {
        threadsByChannel(channelId: $channelId, page: $page) {
    '''
      '${_GqlFragments.threadListFields}'
      r'''
        }
      }
    ''');

  static final getBlockedUser = gql('''
      query GetBlockedUser {
        blockedUsers {
          id
          nickname
          gender
          avatar
          groups {
            id
          }
        }
      }
    ''');

  static final getUserThreadList = gql(r'''
      query GetUserThreadList($userId: String!, $page: Int!) {
        threadsByUser(userId: $userId, page: $page) {
    '''
      '${_GqlFragments.threadListFields}'
      r'''
        }
      }
    ''');

  static final sendReply = gql(r'''
      mutation SendReply($threadId: Int!, $parentId: String, $html: String!) {
        replyThread(threadId: $threadId, parentId: $parentId, html: $html) {
          ...CommentsRecursive
        }
      }
    '''
      '${_GqlFragments.commentsRecursive}'
      '${_GqlFragments.commentFields}');

  static final createThread = gql(r'''
      mutation CreateThread($title: String!, $tags: [String!]!, $html: String!) {
        createThread(title: $title, tags: $tags, html: $html)
      }
    ''');

  static final unblockUser = gql(r'''
      mutation UnblockUser($userId: String!) {
        unblockUser(id: $userId)
      }
    ''');

  static final blockUser = gql(r'''
      mutation BlockUser($userId: String!) {
        blockUser(id: $userId)
      }
    ''');

  static final getInstalledPacks = gql('''
      query GetInstalledPacks {
        installedPacks {
          id
          title
          smilies {
            id
            alt
            width
            height
          }
        }
      }
    ''');
}

class HKGaldenApi {
  // OAuth public client id — embedded in the shipped binary, not a secret.
  static const String clientId = '15897154848030720.apis.hkgalden.org';
  static final HttpLink _api = HttpLink('https://hkgalden.org/_');

  static final AuthLink _bearerToken = AuthLink(getToken: () async {
    final String? tokenString = Hive.box('token').get('token') as String?;
    return 'Bearer $tokenString';
  });

  static final Link _link = _bearerToken.concat(_api);

  HKGaldenApi({GraphQLClient? client})
      : _client = client ??
            GraphQLClient(
              cache: GraphQLCache(),
              defaultPolicies: DefaultPolicies(
                  query: Policies(fetch: FetchPolicy.networkOnly)),
              link: _link,
            );

  final GraphQLClient _client;

  final InflightCache<int, List<SmileyPack>?> _packsCache = InflightCache();

  /// Last successful fetch, or empty when nothing has been loaded yet.
  List<SmileyPack> get cachedPacks => _packsCache.peek(0) ?? const [];

  /// Returns cached packs when present; otherwise fetches (coalescing in-flight).
  Future<List<SmileyPack>?> getInstalledPacks() {
    return _packsCache.get(0, getInstalledPacksQuery, cacheNulls: false);
  }

  /// Fire-and-forget fetch so compose can read [cachedPacks] immediately.
  void prewarm() {
    getInstalledPacks();
  }

  void clearPacksCache() => _packsCache.clear();

  /// Returns null on failure. Runs a query or mutation and parses its data.
  Future<T?> _run<T>(
    Future<QueryResult> Function() op, {
    required FutureOr<T> Function(Map<String, dynamic> data) parse,
  }) async {
    final QueryResult result = await op();
    if (result.hasException || result.data == null) {
      return null;
    }
    return parse(result.data!);
  }

  Future<List<Channel>?> getChannelsQuery() {
    return _run(
      () => _client.query(
          QueryOptions(document: _GqlFragments.getChannels)),
      parse: (data) async {
        final List<dynamic> result = data['channels'] as List<dynamic>;
        return compute(channelFromJson, result);
      },
    );
  }

  Future<User?> getSessionUserQuery() {
    return _run(
      () => _client.query(
          QueryOptions(document: _GqlFragments.getSessionUser)),
      parse: (data) async {
        final Map<String, dynamic> result =
            data['sessionUser'] as Map<String, dynamic>;
        return compute(userFromJson, result);
      },
    );
  }

  Future<Thread?> getThreadQuery(int threadId, int page) {
    return _run(
      () => _client.query(QueryOptions(
        document: _GqlFragments.getThread,
        variables: <String, dynamic>{
          'id': threadId,
          'page': page,
        },
      )),
      parse: (data) async {
        final Map<String, dynamic> result =
            data['thread'] as Map<String, dynamic>;
        return compute(threadFromJson, result);
      },
    );
  }

  Future<List<Thread>?> getThreadListQuery(String channelId, int page) {
    return _run(
      () => _client.query(QueryOptions(
        document: _GqlFragments.getThreadList,
        variables: <String, dynamic>{
          'channelId': channelId,
          'page': page,
        },
      )),
      parse: (data) async {
        final List<dynamic> result =
            data['threadsByChannel'] as List<dynamic>;
        return compute(threadListFromJson, result);
      },
    );
  }

  Future<List<User>?> getBlockedUser() {
    return _run(
      () => _client.query(
          QueryOptions(document: _GqlFragments.getBlockedUser)),
      parse: (data) async {
        final List<dynamic> result = data['blockedUsers'] as List<dynamic>;
        return compute(userListFromJson, result);
      },
    );
  }

  Future<List<Thread>?> getUserThreadList(String userId, int page) {
    return _run(
      () => _client.query(QueryOptions(
        document: _GqlFragments.getUserThreadList,
        variables: <String, dynamic>{
          'userId': userId,
          'page': page,
        },
      )),
      parse: (data) async {
        final List<dynamic> result = data['threadsByUser'] as List<dynamic>;
        return compute(threadListFromJson, result);
      },
    );
  }

  Future<Reply?> sendReply(int threadId, String html, {String? parentId}) {
    return _run(
      () => _client.mutate(MutationOptions(
        document: _GqlFragments.sendReply,
        variables: <String, dynamic>{
          'threadId': threadId,
          'parentId': parentId,
          'html': html,
        },
      )),
      parse: (data) async {
        final dynamic resultJson = data['replyThread'];
        return compute(replyFromJson, resultJson);
      },
    );
  }

  Future<int?> createThread(String title, List<String> tags, String html) {
    return _run(
      () => _client.mutate(MutationOptions(
        document: _GqlFragments.createThread,
        variables: <String, dynamic>{
          'title': title,
          'tags': tags,
          'html': html,
        },
      )),
      parse: (data) => data['createThread'] as int,
    );
  }

  Future<bool?> unblockUser(String userId) {
    return _run(
      () => _client.mutate(MutationOptions(
        document: _GqlFragments.unblockUser,
        variables: <String, dynamic>{'userId': userId},
      )),
      parse: (data) => data['unblockUser'] as bool,
    );
  }

  Future<bool?> blockUser(String userId) {
    return _run(
      () => _client.mutate(MutationOptions(
        document: _GqlFragments.blockUser,
        variables: <String, dynamic>{'userId': userId},
      )),
      parse: (data) => data['blockUser'] as bool,
    );
  }

  /// Returns installed smiley packs (empty list when unauthenticated).
  Future<List<SmileyPack>?> getInstalledPacksQuery() {
    return _run(
      () => _client.query(
          QueryOptions(document: _GqlFragments.getInstalledPacks)),
      parse: (data) {
        final List<dynamic> result =
            data['installedPacks'] as List<dynamic>? ?? const [];
        return result
            .map((e) => SmileyPack.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }
}
