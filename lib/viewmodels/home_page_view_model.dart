import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';

class HomePageViewModel {
  final List<Thread> threads;
  final String title;
  final String selectedChannelId;
  final Function(String) onRefresh;

  HomePageViewModel({
    this.threads,
    this.title,
    this.onRefresh,
    this.selectedChannelId,
  });

  factory HomePageViewModel.create(Store<AppState> store) {
    return HomePageViewModel(
      threads: store.state.threadState.threads,
      title: store.state.channelState.channels.where(
        (channel) => channel.channelId == store.state.channelState.selectedChannelId)
      .first.channelName,
      selectedChannelId: store.state.channelState.selectedChannelId,
      onRefresh: (channelId) => store.dispatch(RequestThreadAction(channelId: channelId)),
    );
  }
}