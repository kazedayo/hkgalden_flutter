import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';
import 'package:hkgalden_flutter/redux/thread_list/thread_list_action.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';

class HomePageViewModel {
  final List<Thread> threads;
  final String title;
  final Function(String) onRefresh;
  final Function(int) onThreadCellTap;
  final String selectedChannelId;
  final bool isThreadLoading;
  final bool isRefresh;

  HomePageViewModel({
    this.threads,
    this.title,
    this.onRefresh,
    this.onThreadCellTap,
    this.selectedChannelId,
    this.isThreadLoading,
    this.isRefresh,
  });

  factory HomePageViewModel.create(Store<AppState> store) {
    return HomePageViewModel(
      threads: store.state.threadListState.threads,
      title: store.state.channelState.channels.where(
        (channel) => channel.channelId == store.state.channelState.selectedChannelId)
      .first.channelName,
      onRefresh: (channelId) => store.dispatch(RequestThreadListAction(channelId: channelId, page: 1,isRefresh: true)),
      onThreadCellTap: (threadId) => store.dispatch(RequestThreadAction(threadId: threadId, page: 1, isInitialLoad: true)),
      selectedChannelId: store.state.channelState.selectedChannelId,
      isThreadLoading: store.state.threadListState.threadListIsLoading,
      isRefresh: store.state.threadListState.isRefresh,
    );
  }
}