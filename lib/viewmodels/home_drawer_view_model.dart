import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';

class HomeDrawerViewModel {
  final List<Channel> channels;

  HomeDrawerViewModel({
    this.channels,
  });

  factory HomeDrawerViewModel.create(Store<AppState> store) {
    return HomeDrawerViewModel(
      channels: store.state.channelState.channels,
    );
  }
}