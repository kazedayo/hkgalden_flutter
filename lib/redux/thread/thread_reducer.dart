import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:hkgalden_flutter/redux/thread/thread_state.dart';
import 'package:redux/redux.dart';

final Reducer<ThreadState> threadReducer = combineReducers([
  TypedReducer<ThreadState, RequestThreadAction>(requestThreadReducer),
  TypedReducer<ThreadState, UpdateThreadAction>(updateThreadReducer),
  TypedReducer<ThreadState, RequestThreadErrorAction>(requestThreadErrorReducer),
]);

ThreadState requestThreadReducer(ThreadState state, RequestThreadAction action) {
  return state.copyWith(threadIsLoading: true, isInitialLoad: action.isInitialLoad);
}

ThreadState updateThreadReducer(ThreadState state, UpdateThreadAction action) {
  if (action.isInitialLoad == true) {
    return state.copyWith(threadIsLoading: false, thread: action.thread, isInitialLoad: false, currentPage: action.page);
  } else {
    return state.copyWith(threadIsLoading: false, thread: state.thread.copyWith(replies: state.thread.replies..addAll(action.thread.replies), totalReplies: action.thread.totalReplies), isInitialLoad: false, currentPage: action.page);
  }
}

ThreadState requestThreadErrorReducer(ThreadState state, RequestThreadErrorAction action) {
  return state.copyWith(threadIsLoading: false, isInitialLoad: false);
}
