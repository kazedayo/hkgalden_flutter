import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/channel/channel_action.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:redux/redux.dart';

class HomeDrawerViewModel {
  final List<Channel> channels;
  final Function(String) onTap;

  HomeDrawerViewModel({
    this.channels,
    this.onTap,
  });

  factory HomeDrawerViewModel.create(Store<AppState> store) {
    return HomeDrawerViewModel(
      channels: store.state.channelState.channels,
      onTap: (channelId) {
        store.dispatch(RequestThreadAction(channelId: channelId));
        store.dispatch(SetSelectedChannelId(channelId: channelId));
      },
    );
  }
}