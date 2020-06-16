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
      List<Thread> threads = await _getThreadsQuery(action.channelId);
      next(UpdateThreadAction(threads: threads));
    } else {
      next(action);
    }
  }

  Future<List<Thread>> _getThreadsQuery(String channelId) async {
    final client = HKGaldenApi().client;

    const String query = r'''
      query ThreadsQuery($channelId: String!, $page: Int!) {
        threadsByChannel(channelId: $channelId, page: $page) {
          id
          title
          replies {
            authorNickname
            date
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
        'page': 1
      },
    );

    final QueryResult queryResult = await client.query(options);

    if (queryResult.hasException) {
      print(queryResult.exception.toString());
    }

    final List<dynamic> result = queryResult.data['threadsByChannel'] as List<dynamic>;

    final List<Thread> threads = result.map((thread) => Thread.fromJson(thread)).toList();

    return threads;
  }
}