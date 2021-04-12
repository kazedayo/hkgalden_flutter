import 'package:graphql/client.dart';
import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/utils/token_store.dart';

class HKGaldenApi {
  static const String clientId = '15897154848030720.apis.hkgalden.org';
  static final HttpLink _api = HttpLink('https://hkgalden.org/_');

  static final AuthLink _bearerToken = AuthLink(getToken: () async {
    final String? tokenString =
        await TokenStore().tokenBox.get('token') as String?;
    //print(tokenString);
    return 'Bearer $tokenString';
  });

  static final Link _link = _bearerToken.concat(_api);

  final GraphQLClient _client = GraphQLClient(
    cache: GraphQLCache(),
    link: _link,
  );

  Future<List<Channel>?> getChannelsQuery() async {
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

    final QueryOptions options = QueryOptions(
      document: gql(query),
    );

    final QueryResult queryResult = await _client.query(options);

    if (queryResult.hasException) {
      return null;
    } else {
      final List<dynamic> result =
          queryResult.data!['channels'] as List<dynamic>;

      final List<Channel> threads = result
          .map((thread) => Channel.fromJson(thread as Map<String, dynamic>))
          .toList();

      return threads;
    }
  }

  Future<User?> getSessionUserQuery() async {
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

    final QueryOptions options = QueryOptions(
      document: gql(query),
    );

    final QueryResult queryResult = await _client.query(options);

    if (queryResult.hasException) {
      return null;
    } else {
      final dynamic result = queryResult.data!['sessionUser'] as dynamic;

      final User sessionUser = User.fromJson(result as Map<String, dynamic>);

      return sessionUser;
    }
  }

  Future<Thread?> getThreadQuery(int threadId, int page) async {
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
      document: gql(query),
      variables: <String, dynamic>{
        'id': threadId,
        'page': page,
      },
    );

    final QueryResult queryResult = await _client.query(options);

    if (queryResult.hasException) {
      return null;
    } else {
      final dynamic result = queryResult.data!['thread'] as dynamic;

      final Thread thread = Thread.fromJson(result as Map<String, dynamic>);

      return thread;
    }
  }

  Future<List<Thread>?> getThreadListQuery(
      String channelId, int page) async {
    const String query = r'''
      query GetThreadListQuery($channelId: String!, $page: Int!) {
        threadsByChannel(channelId: $channelId, page: $page) {
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
          tags{
            name
            color
          }
        }
      }
    ''';

    final QueryOptions options = QueryOptions(
      document: gql(query),
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
          queryResult.data!['threadsByChannel'] as List<dynamic>;

      final List<Thread> threads = result
          .map((thread) => Thread.fromJson(thread as Map<String, dynamic>))
          .toList();

      return threads;
    }
  }

  Future<List<User>?> getBlockedUser() async {
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

    final QueryOptions options = QueryOptions(document: gql(query));

    final QueryResult queryResult = await _client.query(options);

    if (queryResult.hasException) {
      return null;
    } else {
      final List<dynamic> result =
          queryResult.data!['blockedUsers'] as List<dynamic>;

      final List<User> blockedUsers = result
          .map((user) => User.fromJson(user as Map<String, dynamic>))
          .toList();

      return blockedUsers;
    }
  }

  Future<List<Thread>?> getUserThreadList(String userId, int page) async {
    const String query = r'''
      query GetUserThreadList($userId: String!, $page: Int!) {
        threadsByUser(userId: $userId, page: $page) {
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
          tags{
            name
            color
          }
        }
      }
    ''';

    final QueryOptions options =
        QueryOptions(document: gql(query), variables: <String, dynamic>{
      'userId': userId,
      'page': page,
    });

    final QueryResult queryResult = await _client.query(options);

    if (queryResult.hasException) {
      return null;
    } else {
      final List<dynamic> result =
          queryResult.data!['threadsByUser'] as List<dynamic>;

      final List<Thread> userThreads = result
          .map((e) => Thread.fromJson(e as Map<String, dynamic>))
          .toList();

      return userThreads;
    }
  }

  Future<Reply?> sendReply(int threadId, String html,
      {String? parentId}) async {
    const String mutation = r'''
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

    final MutationOptions options =
        MutationOptions(document: gql(mutation), variables: <String, dynamic>{
      'threadId': threadId,
      'parentId': parentId,
      'html': html,
    });

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      return null;
    } else {
      final dynamic resultJson = result.data!['replyThread'] as dynamic;
      final Reply sentReply = Reply.fromJson(resultJson);
      return sentReply;
    }
  }

  Future<int?> createThread(
      String title, List<String> tags, String html) async {
    const String mutation = r'''
      mutation CreateThread($title: String!, $tags: [String!]!, $html: String!) {
        createThread(title: $title, tags: $tags, html: $html)
      }
    ''';

    final MutationOptions options =
        MutationOptions(document: gql(mutation), variables: <String, dynamic>{
      'title': title,
      'tags': tags,
      'html': html,
    });

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      return null;
    } else {
      final int threadId = result.data!['createThread'] as int;
      return threadId;
    }
  }

  Future<bool?> unblockUser(String userId) async {
    const String mutation = r'''
      mutation UnblockUser($userId: String!) {
        unblockUser(id: $userId)
      }
    ''';

    final MutationOptions options = MutationOptions(
        document: gql(mutation),
        variables: <String, dynamic>{'userId': userId});

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      return null;
    } else {
      final bool isSuccess = result.data!['unblockUser'] as bool;
      return isSuccess;
    }
  }

  Future<bool?> blockUser(String userId) async {
    const String mutation = r'''
      mutation BlockUser($userId: String!) {
        blockUser(id: $userId)
      }
    ''';

    final MutationOptions options = MutationOptions(
        document: gql(mutation),
        variables: <String, dynamic>{'userId': userId});

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      return null;
    } else {
      final bool isSuccess = result.data!['blockUser'] as bool;
      return isSuccess;
    }
  }
}
