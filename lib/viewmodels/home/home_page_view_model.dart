import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';
import 'package:hkgalden_flutter/redux/thread_list/thread_list_action.dart';

class HomePageViewModel extends Equatable {
  final bool isLoggedIn;
  final List<Thread> threads;
  final String title;
  final String selectedChannelId;
  final bool isThreadLoading;
  final bool isRefresh;
  final Function(String) onRefresh;
  final Function(String) onCreateThread;
  final List<String> blockedUserIds;

  HomePageViewModel(
      {this.isLoggedIn,
      this.threads,
      this.title,
      this.selectedChannelId,
      this.isThreadLoading,
      this.isRefresh,
      this.onRefresh,
      this.onCreateThread,
      this.blockedUserIds});

  factory HomePageViewModel.create(Store<AppState> store) {
    return HomePageViewModel(
      isLoggedIn: store.state.sessionUserState.isLoggedIn,
      threads: store.state.threadListState.threads,
      title: store.state.channelState.channels
          .where((channel) =>
              channel.channelId == store.state.channelState.selectedChannelId)
          .first
          .channelName,
      selectedChannelId: store.state.channelState.selectedChannelId,
      isThreadLoading: store.state.threadListState.threadListIsLoading,
      isRefresh: store.state.threadListState.isRefresh,
      onRefresh: (channelId) => store.dispatch(RequestThreadListAction(
          channelId: channelId, page: 1, isRefresh: true)),
      onCreateThread: (channelId) => store.dispatch(RequestThreadListAction(
          channelId: channelId, page: 1, isRefresh: false)),
      blockedUserIds: store.state.sessionUserState.sessionUser.blockedUsers,
    );
  }

  List<Object> get props => [
        isLoggedIn,
        threads,
        title,
        selectedChannelId,
        isThreadLoading,
        isRefresh,
        blockedUserIds,
      ];
}
