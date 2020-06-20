import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_action.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_state.dart';
import 'package:redux/redux.dart';

final Reducer<SessionUserState> sessionUserReducer = combineReducers([
  TypedReducer<SessionUserState, RequestSessionUserAction>(requestSessionUserReducer),
  TypedReducer<SessionUserState, UpdateSessionUserAction>(updateSessionUserReducer),
  TypedReducer<SessionUserState, RequestSessionUserErrorAction>(requestSessionUserErrorReducer),
  TypedReducer<SessionUserState, RemoveSessionUserAction>(removeSessionUserReducer),
]);

SessionUserState requestSessionUserReducer(SessionUserState state, RequestSessionUserAction action) {
  return state.copyWith(isLoading: true);
}

SessionUserState updateSessionUserReducer(SessionUserState state, UpdateSessionUserAction action) {
  return state.copyWith(isLoading: false, sessionUser: action.sessionUser);
}

SessionUserState requestSessionUserErrorReducer(SessionUserState state, RequestSessionUserErrorAction action) {
  return state.copyWith(isLoading: false);
}

SessionUserState removeSessionUserReducer(SessionUserState state, RemoveSessionUserAction action) {
  return state.copyWith(isLoading: false, sessionUser: User(
    userId: '',
    nickName: '',
    avatar: '',
    userGroup: [],
    blockedUsers: [],
  ));
}