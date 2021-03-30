import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:redux/redux.dart';

class ThreadMiddleware extends MiddlewareClass<AppState> {
  @override
  Future<void> call(
      Store<AppState> store, dynamic action, NextDispatcher next) async {
    next(action);
    if (action is RequestThreadAction) {
      final Thread? thread = await HKGaldenApi()
          .getThreadQuery(action.threadId, action.page, action.isInitialLoad);
      thread == null
          ? next(RequestThreadErrorAction(
              action.threadId, action.page, action.isInitialLoad))
          : next(UpdateThreadAction(
              thread: thread,
              page: action.page,
              isInitialLoad: action.isInitialLoad));
    } else if (action is RequestThreadErrorAction) {
      next(RequestThreadAction(
          threadId: action.threadId,
          page: action.page,
          isInitialLoad: action.isInitialLoad));
    }
  }
}
