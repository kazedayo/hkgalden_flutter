import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:hkgalden_flutter/redux/thread/thread_state.dart';
import 'package:redux/redux.dart';

import 'package:hkgalden_flutter/models/reply.dart';

final Reducer<ThreadState> threadReducer = combineReducers([
  TypedReducer<ThreadState, RequestThreadAction>(requestThreadReducer),
  TypedReducer<ThreadState, UpdateThreadAction>(updateThreadReducer),
  TypedReducer<ThreadState, AppendReplyToThreadAction>(
      appendReplyToThreadReducer),
  TypedReducer<ThreadState, ClearThreadStateAction>(clearThreadStateReducer),
]);

ThreadState requestThreadReducer(
    ThreadState state, RequestThreadAction action) {
  return state.copyWith(
      threadIsLoading: true, isInitialLoad: action.isInitialLoad);
}

ThreadState updateThreadReducer(ThreadState state, UpdateThreadAction action) {
  if (action.isInitialLoad == true) {
    return state.copyWith(
        threadIsLoading: false,
        thread: action.thread,
        isInitialLoad: false,
        currentPage: action.page,
        endPage: action.page);
  } else {
    if (action.page < state.endPage) {
      return state.copyWith(
          threadIsLoading: false,
          previousPages: action.thread.copyWith(
              replies: state.previousPages.replies == null
                  ? action.thread.replies
                  : (action.thread.replies
                    ..addAll(state.previousPages.replies)),
              totalReplies: action.thread.totalReplies),
          isInitialLoad: false,
          currentPage: action.page);
    }
    return state.copyWith(
        threadIsLoading: false,
        thread: state.thread.copyWith(
            replies: state.thread.replies..addAll(action.thread.replies),
            totalReplies: action.thread.totalReplies),
        isInitialLoad: false,
        currentPage: action.page,
        endPage: action.page);
  }
}

ThreadState appendReplyToThreadReducer(
    ThreadState state, AppendReplyToThreadAction action) {
  List<Reply> replies = state.thread.replies.toList();
  replies.add(action.reply);
  return state.copyWith(thread: state.thread.copyWith(replies: replies));
}

ThreadState clearThreadStateReducer(
    ThreadState state, ClearThreadStateAction action) {
  return ThreadState.initial();
}
