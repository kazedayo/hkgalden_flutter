import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_action.dart';
import 'package:hkgalden_flutter/secure_storage/token_secure_storage.dart';
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
  final Function onLogout;
  final List<String> blockedUserIds;
  final User sessionUser;

  HomePageViewModel(
      {this.isLoggedIn,
      this.threads,
      this.title,
      this.selectedChannelId,
      this.isThreadLoading,
      this.isRefresh,
      this.onRefresh,
      this.onCreateThread,
      this.onLogout,
      this.blockedUserIds,
      this.sessionUser});

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
        onLogout: () {
          TokenSecureStorage().writeToken('', onFinish: (_) {
            store.dispatch(RemoveSessionUserAction());
            store.dispatch(RequestThreadListAction(
                channelId: store.state.channelState.selectedChannelId,
                page: 1,
                isRefresh: false));
          });
        },
        blockedUserIds: store.state.sessionUserState.sessionUser.blockedUsers,
        sessionUser: store.state.sessionUserState.sessionUser);
  }

  List<Object> get props => [
        isLoggedIn,
        threads,
        title,
        selectedChannelId,
        isThreadLoading,
        isRefresh,
        blockedUserIds,
        sessionUser
      ];
}
