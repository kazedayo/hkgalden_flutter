import 'dart:async';

import 'package:graphql/client.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:redux/redux.dart';

class ThreadMiddleware extends MiddlewareClass<AppState> {
  @override
  void call(Store<AppState> store, dynamic action, NextDispatcher next) async {
    if (action is RequestThreadAction) {
      next(action);
      Thread thread = await _getThreadQuery(action.threadId, action.page, action.isInitialLoad, next);
      next(UpdateThreadAction(thread: thread, page: action.page, isInitialLoad: action.isInitialLoad));
    } else if (action is RequestThreadErrorAction) {
      next(RequestThreadAction(threadId: action.threadId, page: action.page, isInitialLoad: action.isInitialLoad));
    } else {
      next(action);
    }
  }

  Future<Thread> _getThreadQuery(int threadId, int page, bool isInitialLoad, NextDispatcher next) async {
    final client = HKGaldenApi().client;

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
        'id' : threadId,
        'page': page,
      },
    );

    final QueryResult queryResult = await client.query(options);

    if (queryResult.hasException) {
      next(RequestThreadAction(threadId: threadId, page: page, isInitialLoad: isInitialLoad));
    }

    final dynamic result = queryResult.data['thread'] as dynamic;

    final Thread thread = Thread.fromJson(result);

    return thread;
  }
}