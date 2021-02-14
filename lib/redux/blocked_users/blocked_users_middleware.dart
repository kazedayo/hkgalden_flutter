import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/blocked_users/blocked_users_action.dart';
import 'package:redux/redux.dart';

class BlockedUsersMiddleware extends MiddlewareClass<AppState> {
  @override
  Future<void> call(
      Store<AppState> store, dynamic action, NextDispatcher next) async {
    next(action);
    if (action is RequestBlockedUsersAction) {
      final List<User> blockedUsers = await HKGaldenApi().getBlockedUser();
      next(UpdateBlockedUsersAction(blockedUsers));
    }
  }
}
