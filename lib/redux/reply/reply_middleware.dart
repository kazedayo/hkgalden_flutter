import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/reply/reply_action.dart';
import 'package:redux/redux.dart';

class ReplyMiddleware extends MiddlewareClass<AppState> {
  @override
  void call(Store<AppState> store, dynamic action, NextDispatcher next) async {
    next(action);
    if (action is SendReplyAction) {
      //Reply sentReply = await _sendReply(action.threadId, action.html, action.parentId);
      next(SendReplySuccessAction());
    }
  }
}
