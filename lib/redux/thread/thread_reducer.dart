import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:hkgalden_flutter/redux/thread/thread_state.dart';
import 'package:redux/redux.dart';

final Reducer<ThreadState> threadReducer = combineReducers([
  TypedReducer<ThreadState, RequestThreadListAction>(requestThreadListReducer),
  TypedReducer<ThreadState, UpdateThreadListAction>(updateThreadListReducer),
  TypedReducer<ThreadState, RequestThreadAction>(requestThreadReducer),
  TypedReducer<ThreadState, UpdateThreadAction>(updateThreadReducer),
  TypedReducer<ThreadState, RequestThreadListErrorAction>(requestThreadListErrorReducer),
  TypedReducer<ThreadState, RequestThreadErrorAction>(requestThreadErrorReducer),
]);

ThreadState requestThreadListReducer(ThreadState state, RequestThreadListAction action) {
  return state.copyWith(threadListIsLoading: true, isRefresh: action.isRefresh);
}

ThreadState updateThreadListReducer(ThreadState state, UpdateThreadListAction action) {
  return state.copyWith(threadListIsLoading: false, isRefresh: false, threads: action.threads);
}

ThreadState requestThreadReducer(ThreadState state, RequestThreadAction action) {
  return state.copyWith(threadIsLoading: true);
}

ThreadState updateThreadReducer(ThreadState state, UpdateThreadAction action) {
  return state.copyWith(threadIsLoading: false, isRefresh: false, thread: action.thread);
}

ThreadState requestThreadListErrorReducer(ThreadState state, RequestThreadListErrorAction action) {
  return state.copyWith(threadListIsLoading: false, isRefresh: false);
}

ThreadState requestThreadErrorReducer(ThreadState state, RequestThreadErrorAction action) {
  return state.copyWith(threadIsLoading: false, isRefresh: false);
}
