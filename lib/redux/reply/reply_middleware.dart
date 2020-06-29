import 'package:graphql/client.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/reply/reply_action.dart';
import 'package:redux/redux.dart';

class ReplyMiddleware extends MiddlewareClass<AppState> {
  @override
  void call(Store<AppState> store, dynamic action, NextDispatcher next) async {
    next(action);
    if (action is SendReplyAction) {
      Reply sentReply = await _sendReply(action.threadId, action.html, action.parentId);
      next(SendReplySuccessAction());
    }
  }

  Future<Reply> _sendReply(int threadId, String html, String parentId) async {
    final GraphQLClient client = HKGaldenApi().client;

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
      variables: <String, dynamic> {
        'threadId': threadId,
        'parentId': parentId,
        'html': html,
      }
    );

    final QueryResult result = await client.mutate(options);

    if (result.hasException) {
      print(result.exception.toString());
    }

    final dynamic resultJson = result.data['reply'] as dynamic;

    final Reply sentReply = Reply.fromJson(resultJson);

    return sentReply;
  }
}