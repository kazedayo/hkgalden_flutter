import 'package:graphql/client.dart';
import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/secure_storage/token_secure_storage.dart';

class HKGaldenApi {
  static final String clientId = '15897154848030720.apis.hkgalden.org';
  static final HttpLink _api = HttpLink(uri: 'https://hkgalden.org/_');

  static final AuthLink _bearerToken = AuthLink(getToken: () async {
    String tokenString = await TokenSecureStorage().storage.read(key: 'token');
    //print(tokenString);
    return 'Bearer $tokenString';
  });

  static final Link _link = _bearerToken.concat(_api);

  final GraphQLClient _client = GraphQLClient(
    cache: InMemoryCache(),
    link: _link,
  );

  Future<List<Channel>> getChannelsQuery() async {
    const String query = r'''
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

    final QueryOptions options = QueryOptions(
      documentNode: gql(query),
    );

    final QueryResult queryResult = await _client.query(options);

    if (queryResult.hasException) {
      return null;
    } else {
      final List<dynamic> result =
          queryResult.data['channels'] as List<dynamic>;

      final List<Channel> threads =
          result.map((thread) => Channel.fromJson(thread)).toList();

      return threads;
    }
  }

  Future<User> getSessionUserQuery() async {
    const String query = r'''
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

    final QueryOptions options = QueryOptions(
      documentNode: gql(query),
    );

    final QueryResult queryResult = await _client.query(options);

    if (queryResult.hasException) {
      return null;
    } else {
      final dynamic result = queryResult.data['sessionUser'] as dynamic;

      final User sessionUser = User.fromJson(result);

      return sessionUser;
    }
  }

  Future<Thread> getThreadQuery(
      int threadId, int page, bool isInitialLoad) async {
    const String query = r'''
      query GetThreadContent($id: Int!, $page: Int!) {
        thread(id: $id,sorting: date_asc,page: $page) {
          id
            title
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

    final QueryOptions options = QueryOptions(
      documentNode: gql(query),
      variables: <String, dynamic>{
        'id': threadId,
        'page': page,
      },
    );

    final QueryResult queryResult = await _client.query(options);

    if (queryResult.hasException) {
      return null;
    } else {
      final dynamic result = queryResult.data['thread'] as dynamic;

      final Thread thread = Thread.fromJson(result);

      return thread;
    }
  }

  Future<List<Thread>> getThreadListQuery(
      String channelId, int page, bool isRefresh) async {
    const String query = r'''
      query GetThreadListQuery($channelId: String!, $page: Int!) {
        threadsByChannel(channelId: $channelId, page: $page) {
          id
          title
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
          tags{
            name
            color
          }
        }
      }
    ''';

    final QueryOptions options = QueryOptions(
      documentNode: gql(query),
      variables: <String, dynamic>{
        //hardcoded value for now
        'channelId': channelId,
        'page': page,
      },
    );

    final QueryResult queryResult = await _client.query(options);

    if (queryResult.hasException) {
      return null;
    } else {
      final List<dynamic> result =
          queryResult.data['threadsByChannel'] as List<dynamic>;

      final List<Thread> threads =
          result.map((thread) => Thread.fromJson(thread)).toList();

      return threads;
    }
  }

  Future<List<User>> getBlockedUser() async {
    const String query = r'''
      query GetBlockedUser {
        blockedUsers {
          id
          nickname
          gender
        }
      }
    ''';

    final QueryOptions options = QueryOptions(documentNode: gql(query));

    final QueryResult queryResult = await _client.query(options);

    if (queryResult.hasException) {
      return null;
    } else {
      final List<dynamic> result =
          queryResult.data['blockedUsers'] as List<dynamic>;

      final List<User> blockedUsers =
          result.map((user) => User.fromJson(user)).toList();

      return blockedUsers;
    }
  }

  Future<List<Thread>> getUserThreadList(String userId, int page) async {
    final String query = r'''
      query GetUserThreadList($userId: String!, $page: Int!) {
        threadsByUser(userId: $userId, page: $page) {
          id
          title
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
          tags{
            name
            color
          }
        }
      }
    ''';

    final QueryOptions options =
        QueryOptions(documentNode: gql(query), variables: <String, dynamic>{
      'userId': userId,
      'page': page,
    });

    final QueryResult queryResult = await _client.query(options);

    if (queryResult.hasException) {
      return null;
    } else {
      final List<dynamic> result =
          queryResult.data['threadsByUser'] as List<dynamic>;

      final List<Thread> userThreads =
          result.map((e) => Thread.fromJson(e)).toList();

      return userThreads;
    }
  }

  Future<Reply> sendReply(int threadId, String html, {String parentId}) async {
    final String mutation = r'''
      mutation SendReply($threadId: Int!, $parentId: String, $html: String!) {
        replyThread(threadId: $threadId, parentId: $parentId, html: $html) {
          ...CommentsRecursive
        }
      }

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

    final MutationOptions options = MutationOptions(
        documentNode: gql(mutation),
        variables: <String, dynamic>{
          'threadId': threadId,
          'parentId': parentId,
          'html': html,
        });

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      print(result.exception.toString());
      return null;
    } else {
      dynamic resultJson = result.data['replyThread'] as dynamic;
      Reply sentReply = Reply.fromJson(resultJson);
      return sentReply;
    }
  }
}
