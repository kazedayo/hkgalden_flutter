import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gql/ast.dart';
import 'package:graphql/client.dart';
import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/smiley_pack.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/models/user.dart';
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
          name
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
          name
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

  static final DocumentNode getChannels = gql('''
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

  static final DocumentNode getSessionUser = gql('''
      query GetSessionUser {
        sessionUser {
          id
          nickname
          avatar
          gender
          groups {
            id
            name
          }
          blockedUserIds
        }
      }
    ''');

  static final DocumentNode getThread = gql(r'''
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

  static final DocumentNode getThreadList = gql(r'''
      query GetThreadListQuery($channelId: String!, $page: Int!) {
        threadsByChannel(channelId: $channelId, page: $page) {
    '''
      '${_GqlFragments.threadListFields}'
      r'''
        }
      }
    ''');

  static final DocumentNode getBlockedUser = gql('''
      query GetBlockedUser {
        blockedUsers {
          id
          nickname
          gender
          avatar
          groups {
            id
            name
          }
        }
      }
    ''');

  static final DocumentNode getUserThreadList = gql(r'''
      query GetUserThreadList($userId: String!, $page: Int!) {
        threadsByUser(userId: $userId, page: $page) {
    '''
      '${_GqlFragments.threadListFields}'
      r'''
        }
      }
    ''');

  static final DocumentNode sendReply = gql(r'''
      mutation SendReply($threadId: Int!, $parentId: String, $html: String!) {
        replyThread(threadId: $threadId, parentId: $parentId, html: $html) {
          ...CommentsRecursive
        }
      }
    '''
      '${_GqlFragments.commentsRecursive}'
      '${_GqlFragments.commentFields}');

  static final DocumentNode createThread = gql(r'''
      mutation CreateThread($title: String!, $tags: [String!]!, $html: String!) {
        createThread(title: $title, tags: $tags, html: $html)
      }
    ''');

  static final DocumentNode unblockUser = gql(r'''
      mutation UnblockUser($userId: String!) {
        unblockUser(id: $userId)
      }
    ''');

  static final DocumentNode blockUser = gql(r'''
      mutation BlockUser($userId: String!) {
        blockUser(id: $userId)
      }
    ''');

  static final DocumentNode getInstalledPacks = gql('''
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
                  query: Policies(fetch: FetchPolicy.cacheAndNetwork)),
              link: _link,
            );

  final GraphQLClient _client;

  /// Returns null on failure. Prefer networkOnly — cache is keyed by thread id.
  Future<T?> _query<T>(
    DocumentNode document, {
    Map<String, dynamic>? variables,
    FetchPolicy? fetchPolicy,
    required FutureOr<T> Function(Map<String, dynamic> data) parse,
  }) async {
    final QueryResult result = await _client.query(QueryOptions(
      document: document,
      variables: variables ?? const {},
      fetchPolicy: fetchPolicy,
    ));
    if (result.hasException || result.data == null) {
      return null;
    }
    return parse(result.data!);
  }

  /// Returns null on failure.
  Future<T?> _mutate<T>(
    DocumentNode document, {
    Map<String, dynamic>? variables,
    required FutureOr<T> Function(Map<String, dynamic> data) parse,
  }) async {
    final QueryResult result = await _client.mutate(MutationOptions(
      document: document,
      variables: variables ?? const {},
    ));
    if (result.hasException || result.data == null) {
      return null;
    }
    return parse(result.data!);
  }

  Future<List<Channel>?> getChannelsQuery() {
    return _query(
      _GqlFragments.getChannels,
      parse: (data) async {
        final List<dynamic> result = data['channels'] as List<dynamic>;
        return compute(channelFromJson, result);
      },
    );
  }

  Future<User?> getSessionUserQuery() {
    return _query(
      _GqlFragments.getSessionUser,
      parse: (data) async {
        final Map<String, dynamic> result =
            data['sessionUser'] as Map<String, dynamic>;
        return compute(userFromJson, result);
      },
    );
  }

  Future<Thread?> getThreadQuery(int threadId, int page) {
    return _query(
      _GqlFragments.getThread,
      variables: <String, dynamic>{
        'id': threadId,
        'page': page,
      },
      fetchPolicy: FetchPolicy.networkOnly,
      parse: (data) async {
        final Map<String, dynamic> result =
            data['thread'] as Map<String, dynamic>;
        return compute(threadFromJson, result);
      },
    );
  }

  Future<List<Thread>?> getThreadListQuery(String channelId, int page) {
    return _query(
      _GqlFragments.getThreadList,
      variables: <String, dynamic>{
        'channelId': channelId,
        'page': page,
      },
      fetchPolicy: FetchPolicy.networkOnly,
      parse: (data) async {
        final List<dynamic> result =
            data['threadsByChannel'] as List<dynamic>;
        return compute(threadListFromJson, result);
      },
    );
  }

  Future<List<User>?> getBlockedUser() {
    return _query(
      _GqlFragments.getBlockedUser,
      parse: (data) async {
        final List<dynamic> result = data['blockedUsers'] as List<dynamic>;
        return compute(userListFromJson, result);
      },
    );
  }

  Future<List<Thread>?> getUserThreadList(String userId, int page) {
    return _query(
      _GqlFragments.getUserThreadList,
      variables: <String, dynamic>{
        'userId': userId,
        'page': page,
      },
      fetchPolicy: FetchPolicy.networkOnly,
      parse: (data) async {
        final List<dynamic> result = data['threadsByUser'] as List<dynamic>;
        return compute(threadListFromJson, result);
      },
    );
  }

  Future<Reply?> sendReply(int threadId, String html, {String? parentId}) {
    return _mutate(
      _GqlFragments.sendReply,
      variables: <String, dynamic>{
        'threadId': threadId,
        'parentId': parentId,
        'html': html,
      },
      parse: (data) async {
        final dynamic resultJson = data['replyThread'];
        return compute(replyFromJson, resultJson);
      },
    );
  }

  Future<int?> createThread(String title, List<String> tags, String html) {
    return _mutate(
      _GqlFragments.createThread,
      variables: <String, dynamic>{
        'title': title,
        'tags': tags,
        'html': html,
      },
      parse: (data) => data['createThread'] as int,
    );
  }

  Future<bool?> unblockUser(String userId) {
    return _mutate(
      _GqlFragments.unblockUser,
      variables: <String, dynamic>{'userId': userId},
      parse: (data) => data['unblockUser'] as bool,
    );
  }

  Future<bool?> blockUser(String userId) {
    return _mutate(
      _GqlFragments.blockUser,
      variables: <String, dynamic>{'userId': userId},
      parse: (data) => data['blockUser'] as bool,
    );
  }

  /// Returns installed smiley packs (empty list when unauthenticated).
  Future<List<SmileyPack>?> getInstalledPacksQuery() {
    return _query(
      _GqlFragments.getInstalledPacks,
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
