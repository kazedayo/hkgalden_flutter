import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:meta/meta.dart';

part 'channel_event.dart';
part 'channel_state.dart';

class ChannelBloc extends Bloc<ChannelEvent, ChannelState> {
  ChannelBloc() : super(ChannelState.initial());

  @override
  Stream<ChannelState> mapEventToState(ChannelEvent event) async* {
    if (event is RequestChannelsEvent) {
      final List<Channel>? channels = await HKGaldenApi().getChannelsQuery();
      if (channels != null) {
        yield state.copyWith(channels: channels);
      }
    } else if (event is SetSelectedChannelEvent) {
      yield state.copyWith(selectedChannelId: event.channelId);
    }
  }
}
