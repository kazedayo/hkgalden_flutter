import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:graphql/client.dart';
import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/utils/token_store.dart';

/// GraphQL document fragments shared across thread/reply operations.
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
            parent {
              ...CommentFields
            }
          }
        }
      }
    }
  ''';

  /// Selection set for list-style thread items (channel / user thread lists).
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
}

class HKGaldenApi {
  static final String clientId = dotenv.get('HKGALDEN_CLIENT_ID');
  static final HttpLink _api = HttpLink('https://hkgalden.org/_');

  static final AuthLink _bearerToken = AuthLink(getToken: () async {
    final String? tokenString =
        await TokenStore().tokenBox.get('token') as String?;
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

  /// Runs a query and returns null on GraphQL/network failure.
  ///
  /// [fetchPolicy] defaults to the client default (`cacheAndNetwork`). Prefer
  /// [FetchPolicy.networkOnly] for list queries: with `cacheAndNetwork`, a
  /// cache hit returns immediately and never waits for the network, so stale
  /// `Thread.replies` (overwritten by a detail fetch) can show wrong last-reply
  /// times.
  Future<T?> _query<T>(
    String document, {
    Map<String, dynamic>? variables,
    FetchPolicy? fetchPolicy,
    required FutureOr<T> Function(Map<String, dynamic> data) parse,
  }) async {
    final QueryResult result = await _client.query(QueryOptions(
      document: gql(document),
      variables: variables ?? const {},
      fetchPolicy: fetchPolicy,
    ));
    if (result.hasException || result.data == null) {
      return null;
    }
    return parse(result.data!);
  }

  /// Runs a mutation and returns null on GraphQL/network failure.
  Future<T?> _mutate<T>(
    String document, {
    Map<String, dynamic>? variables,
    required FutureOr<T> Function(Map<String, dynamic> data) parse,
  }) async {
    final QueryResult result = await _client.mutate(MutationOptions(
      document: gql(document),
      variables: variables ?? const {},
    ));
    if (result.hasException || result.data == null) {
      return null;
    }
    return parse(result.data!);
  }

  Future<List<Channel>?> getChannelsQuery() {
    const String query = '''
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
    ''';

    return _query(
      query,
      parse: (data) async {
        final List<dynamic> result = data['channels'] as List<dynamic>;
        return compute(channelFromJson, result);
      },
    );
  }

  Future<User?> getSessionUserQuery() {
    const String query = '''
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
    ''';

    return _query(
      query,
      parse: (data) async {
        final Map<String, dynamic> result =
            data['sessionUser'] as Map<String, dynamic>;
        return compute(userFromJson, result);
      },
    );
  }

  Future<Thread?> getThreadQuery(int threadId, int page) {
    const String query = r'''
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
        '${_GqlFragments.commentFields}';

    return _query(
      query,
      variables: <String, dynamic>{
        'id': threadId,
        'page': page,
      },
      parse: (data) async {
        final Map<String, dynamic> result =
            data['thread'] as Map<String, dynamic>;
        return compute(threadFromJson, result);
      },
    );
  }

  Future<List<Thread>?> getThreadListQuery(String channelId, int page) {
    const String query = r'''
      query GetThreadListQuery($channelId: String!, $page: Int!) {
        threadsByChannel(channelId: $channelId, page: $page) {
    '''
        '${_GqlFragments.threadListFields}'
        r'''
        }
      }
    ''';

    return _query(
      query,
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
    const String query = '''
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
    ''';

    return _query(
      query,
      parse: (data) async {
        final List<dynamic> result = data['blockedUsers'] as List<dynamic>;
        return compute(userListFromJson, result);
      },
    );
  }

  Future<List<Thread>?> getUserThreadList(String userId, int page) {
    const String query = r'''
      query GetUserThreadList($userId: String!, $page: Int!) {
        threadsByUser(userId: $userId, page: $page) {
    '''
        '${_GqlFragments.threadListFields}'
        r'''
        }
      }
    ''';

    return _query(
      query,
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
    const String mutation = r'''
      mutation SendReply($threadId: Int!, $parentId: String, $html: String!) {
        replyThread(threadId: $threadId, parentId: $parentId, html: $html) {
          ...CommentsRecursive
        }
      }
    '''
        '${_GqlFragments.commentsRecursive}'
        '${_GqlFragments.commentFields}';

    return _mutate(
      mutation,
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
    const String mutation = r'''
      mutation CreateThread($title: String!, $tags: [String!]!, $html: String!) {
        createThread(title: $title, tags: $tags, html: $html)
      }
    ''';

    return _mutate(
      mutation,
      variables: <String, dynamic>{
        'title': title,
        'tags': tags,
        'html': html,
      },
      parse: (data) => data['createThread'] as int,
    );
  }

  Future<bool?> unblockUser(String userId) {
    const String mutation = r'''
      mutation UnblockUser($userId: String!) {
        unblockUser(id: $userId)
      }
    ''';

    return _mutate(
      mutation,
      variables: <String, dynamic>{'userId': userId},
      parse: (data) => data['unblockUser'] as bool,
    );
  }

  Future<bool?> blockUser(String userId) {
    const String mutation = r'''
      mutation BlockUser($userId: String!) {
        blockUser(id: $userId)
      }
    ''';

    return _mutate(
      mutation,
      variables: <String, dynamic>{'userId': userId},
      parse: (data) => data['blockUser'] as bool,
    );
  }
}
