import 'dart:async';

import 'package:graphql/client.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/thread_list/thread_list_action.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:redux/redux.dart';

class ThreadListMiddleware extends MiddlewareClass<AppState> {
  @override
  void call(Store<AppState> store, dynamic action, NextDispatcher next) async {
    next(action);
    if (action is RequestThreadListAction) {
      List<Thread> threads = await _getThreadListQuery(
          action.channelId, action.page, action.isRefresh, next);
      threads == null
          ? next(RequestThreadListErrorAction(
              action.channelId, action.page, action.isRefresh))
          : next(UpdateThreadListAction(
              threads: threads,
              isRefresh: action.isRefresh,
              page: action.page));
    } else if (action is RequestThreadListErrorAction) {
      next(RequestThreadListAction());
    }
  }

  Future<List<Thread>> _getThreadListQuery(
      String channelId, int page, bool isRefresh, NextDispatcher next) async {
    final client = HKGaldenApi().client;

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

    final QueryResult queryResult = await client.query(options);

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
}
