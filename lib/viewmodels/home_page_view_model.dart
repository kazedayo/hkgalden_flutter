import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';

class HomePageViewModel {
  final List<Thread> threads;
  final String title;
  final Function(String) onRefresh;
  final String selectedChannelId;
  final bool isThreadLoading;
  final bool isRefresh;

  HomePageViewModel({
    this.threads,
    this.title,
    this.onRefresh,
    this.selectedChannelId,
    this.isThreadLoading,
    this.isRefresh,
  });

  factory HomePageViewModel.create(Store<AppState> store) {
    return HomePageViewModel(
      threads: store.state.threadState.threads,
      title: store.state.channelState.channels.where(
        (channel) => channel.channelId == store.state.channelState.selectedChannelId)
      .first.channelName,
      onRefresh: (channelId) => store.dispatch(RequestThreadListAction(channelId: channelId, isRefresh: true)),
      selectedChannelId: store.state.channelState.selectedChannelId,
      isThreadLoading: store.state.threadState.threadListIsLoading,
      isRefresh: store.state.threadState.isRefresh,
    );
  }
}