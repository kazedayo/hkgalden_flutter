import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';

class TagSelectorViewModel extends Equatable {
  final List<Channel> channels;

  const TagSelectorViewModel({required this.channels});

  factory TagSelectorViewModel.create(Store<AppState> store) =>
      TagSelectorViewModel(channels: store.state.channelState.channels);

  @override
  List<Object> get props => [channels];
}
