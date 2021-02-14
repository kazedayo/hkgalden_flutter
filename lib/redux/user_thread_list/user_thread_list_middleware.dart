import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/user_thread_list/user_thread_list_action.dart';
import 'package:redux/redux.dart';

class UserThreadListMiddleware extends MiddlewareClass<AppState> {
  @override
  Future<void> call(
      Store<AppState> store, dynamic action, NextDispatcher next) async {
    next(action);
    if (action is RequestUserThreadListAction) {
      final List<Thread> userThreadList =
          await HKGaldenApi().getUserThreadList(action.userId, action.page);
      next(UpdateUserThreadListAction(threads: userThreadList));
    }
  }
}
