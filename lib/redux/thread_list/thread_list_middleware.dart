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
      List<Thread> threads = await HKGaldenApi().getThreadListQuery(
          action.channelId, action.page, action.isRefresh);
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
}
