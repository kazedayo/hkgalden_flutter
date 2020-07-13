import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';

class TagSelectorViewModel {
  final List<Channel> channels;

  TagSelectorViewModel({this.channels});

  factory TagSelectorViewModel.create(Store<AppState> store) =>
      TagSelectorViewModel(channels: store.state.channelState.channels);
}
