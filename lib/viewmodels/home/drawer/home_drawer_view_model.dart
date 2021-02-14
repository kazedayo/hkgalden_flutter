import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/channel/channel_action.dart';
import 'package:hkgalden_flutter/redux/thread_list/thread_list_action.dart';
import 'package:redux/redux.dart';

class HomeDrawerViewModel extends Equatable {
  final List<Channel> channels;
  final String selectedChannelId;
  final Function(String) onTap;
  final bool isLoggedIn;

  const HomeDrawerViewModel(
      {this.channels, this.selectedChannelId, this.onTap, this.isLoggedIn});

  factory HomeDrawerViewModel.create(Store<AppState> store) {
    return HomeDrawerViewModel(
        channels: store.state.channelState.channels,
        selectedChannelId: store.state.channelState.selectedChannelId,
        onTap: (channelId) {
          store.dispatch(SetSelectedChannelId(channelId: channelId));
          store.dispatch(RequestThreadListAction(
              channelId: channelId, page: 1, isRefresh: false));
        },
        isLoggedIn: store.state.sessionUserState.isLoggedIn);
  }

  @override
  List<Object> get props => [channels, selectedChannelId];
}
