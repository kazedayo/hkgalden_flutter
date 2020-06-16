import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:hkgalden_flutter/redux/thread/thread_state.dart';
import 'package:redux/redux.dart';

final Reducer<ThreadState> threadReducer = combineReducers([
  TypedReducer<ThreadState, RequestThreadAction>(requestThreadReducer),
  TypedReducer<ThreadState, UpdateThreadAction>(updateThreadReducer),
  TypedReducer<ThreadState, RequestThreadErrorAction>(requestThreadErrorReducer),
]);

ThreadState requestThreadReducer(ThreadState state, RequestThreadAction action) {
  return state.copyWith(isLoading: true, isRefresh: action.isRefresh);
}

ThreadState updateThreadReducer(ThreadState state, UpdateThreadAction action) {
  return state.copyWith(isLoading: false, isRefresh: false, threads: action.threads);
}

ThreadState requestThreadErrorReducer(ThreadState state, RequestThreadErrorAction action) {
  return state.copyWith(isLoading: false, isRefresh: false);
}
