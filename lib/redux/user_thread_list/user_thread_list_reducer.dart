import 'package:hkgalden_flutter/redux/user_thread_list/user_thread_list_action.dart';
import 'package:hkgalden_flutter/redux/user_thread_list/user_thread_list_state.dart';
import 'package:redux/redux.dart';

final Reducer<UserThreadListState> userThreadListReducer = combineReducers([]);

UserThreadListState requestUserThreadListReducer(
        UserThreadListState state, RequestUserThreadListAction action) =>
    state.copyWith(isLoading: true, page: action.page);

UserThreadListState updateUserThreadListReducer(
        UserThreadListState state, UpdateUserThreadListAction action) =>
    state.copyWith(isLoading: false, userThreadList: action.threads);

UserThreadListState requestUserThreadListErrorReducer(
        UserThreadListState state, RequestUserThreadListErrorAction action) =>
    state.copyWith(isLoading: false);
