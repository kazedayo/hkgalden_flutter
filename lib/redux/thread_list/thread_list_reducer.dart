import 'package:hkgalden_flutter/redux/thread_list/thread_list_action.dart';
import 'package:hkgalden_flutter/redux/thread_list/thread_list_state.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:redux/redux.dart';

final Reducer<ThreadListState> threadListReducer = combineReducers([
  TypedReducer<ThreadListState, RequestThreadListAction>(
      requestThreadListReducer),
  TypedReducer<ThreadListState, UpdateThreadListAction>(
      updateThreadListReducer),
]);

ThreadListState requestThreadListReducer(
    ThreadListState state, RequestThreadListAction action) {
  if (action.isRefresh == false || action.channelId != state.currentChannelId) {
    return state.copyWith(
        threadListIsLoading: true,
        isRefresh: action.isRefresh,
        threads: [],
        currentPage: action.page,
        currentChannelId: action.channelId);
  } else {
    return state.copyWith(
        threadListIsLoading: true,
        isRefresh: action.isRefresh,
        currentPage: action.page,
        currentChannelId: action.channelId);
  }
}

ThreadListState updateThreadListReducer(
    ThreadListState state, UpdateThreadListAction action) {
  List<Thread> threads = state.threads.toList();
  threads.addAll(action.threads);
  if (action.isRefresh == true && action.page == 1) {
    return state.copyWith(
        threadListIsLoading: false, isRefresh: false, threads: action.threads);
  } else {
    return state.copyWith(
        threadListIsLoading: false, isRefresh: false, threads: threads);
  }
}
