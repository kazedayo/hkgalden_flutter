import 'package:hkgalden_flutter/redux/channel/channel_action.dart';
import 'package:hkgalden_flutter/redux/channel/channel_state.dart';
import 'package:redux/redux.dart';

final Reducer<ChannelState> channelReducer = combineReducers([
  TypedReducer<ChannelState, RequestChannelAction>(requestChannelReducer),
  TypedReducer<ChannelState, UpdateChannelAction>(updateChannelReducer),
  TypedReducer<ChannelState, SetSelectedChannelId>(setSelectedChannelIdReducer),
]);

ChannelState requestChannelReducer(ChannelState state, RequestChannelAction action) {
  return state.copyWith(isLoading: true);
}

ChannelState updateChannelReducer(ChannelState state, UpdateChannelAction action) {
  return state.copyWith(isLoading: false, channels: action.channels);
}

ChannelState setSelectedChannelIdReducer(ChannelState state, SetSelectedChannelId action) {
  return state.copyWith(selectedChannelId: action.channelId);
}