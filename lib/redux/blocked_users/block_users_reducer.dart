import 'package:hkgalden_flutter/redux/blocked_users/blocked_users_action.dart';
import 'package:hkgalden_flutter/redux/blocked_users/blocked_users_state.dart';
import 'package:redux/redux.dart';

final Reducer<BlockedUsersState> blockedUsersReducer = combineReducers([]);

BlockedUsersState requestBlockedUsersReducer(
        BlockedUsersState state, RequestBlockedUsersAction action) =>
    state.copyWith(isLoading: true);

BlockedUsersState updateBlockedUsersReducer(
        BlockedUsersState state, UpdateBlockedUsersAction action) =>
    state.copyWith(isLoading: false, blockedUsers: action.blockedUsers);

BlockedUsersState requestBlockedUsersErrorReducer(
        BlockedUsersState state, RequestBlockedUsersErrorAction action) =>
    state.copyWith(isLoading: false);
