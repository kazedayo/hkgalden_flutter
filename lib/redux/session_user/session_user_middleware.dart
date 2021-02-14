import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_action.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:redux/redux.dart';

class SessionUserMiddleware extends MiddlewareClass<AppState> {
  @override
  Future<void> call(
      Store<AppState> store, dynamic action, NextDispatcher next) async {
    next(action);
    if (action is RequestSessionUserAction) {
      final User sessionUser = await HKGaldenApi().getSessionUserQuery();
      sessionUser == null
          ? next(RequestSessionUserErrorAction())
          : next(UpdateSessionUserAction(sessionUser: sessionUser));
    } else if (action is RequestSessionUserErrorAction) {
      next(RequestSessionUserAction());
    }
  }
}
