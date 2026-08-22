import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

part 'channel_state.dart';

class ChannelCubit extends Cubit<ChannelState> {
  ChannelCubit({required HKGaldenApi api})
      : _api = api,
        super(ChannelLoading());

  final HKGaldenApi _api;

  Future<void> requestChannels() async {
    final List<Channel>? channels = await _api.getChannelsQuery();
    if (channels != null) {
      emit(ChannelLoaded(channels: channels, selectedChannelId: 'bw'));
    }
  }

  void setSelectedChannel(String channelId) {
    if (state is! ChannelLoaded) {
      return;
    }
    emit(ChannelLoaded(
        channels: (state as ChannelLoaded).channels,
        selectedChannelId: channelId));
  }
}
