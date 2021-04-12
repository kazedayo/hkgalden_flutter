import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/channel.dart';
import 'package:hkgalden_flutter/repository/channel_repository.dart';

part 'channel_event.dart';
part 'channel_state.dart';

class ChannelBloc extends Bloc<ChannelEvent, ChannelState> {
  ChannelBloc({required ChannelRepository repository})
      : _channelRepository = repository,
        super(ChannelLoading());

  final ChannelRepository _channelRepository;

  @override
  Stream<ChannelState> mapEventToState(ChannelEvent event) async* {
    if (event is RequestChannelsEvent) {
      final List<Channel>? channels = await _channelRepository.getChannels();
      if (channels != null) {
        yield ChannelLoaded(channels: channels, selectedChannelId: 'bw');
      }
    } else if (event is SetSelectedChannelEvent && state is ChannelLoaded) {
      yield ChannelLoaded(
          channels: (state as ChannelLoaded).channels,
          selectedChannelId: event.channelId);
    }
  }
}
