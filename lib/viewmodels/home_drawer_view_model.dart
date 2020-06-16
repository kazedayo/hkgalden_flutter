import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/channel/channel_action.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:redux/redux.dart';

class HomeDrawerViewModel {
  final List<Channel> channels;
  final String selectedChannelId;
  final Function(String) onTap;

  HomeDrawerViewModel({
    this.channels,
    this.selectedChannelId,
    this.onTap,
  });

  factory HomeDrawerViewModel.create(Store<AppState> store) {
    return HomeDrawerViewModel(
      channels: store.state.channelState.channels,
      selectedChannelId: 'bw',
      onTap: (channelId) {
        store.dispatch(SetSelectedChannelId(channelId: channelId));
        store.dispatch(RequestThreadAction(channelId: channelId));
      },
    );
  }
}