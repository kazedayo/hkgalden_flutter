part of 'channel_bloc.dart';

abstract class ChannelEvent extends Equatable {
  const ChannelEvent();

  @override
  List<Object> get props => [];
}

class RequestChannelsEvent extends ChannelEvent {}

class SetSelectedChannelEvent extends ChannelEvent {
  const SetSelectedChannelEvent({required this.channelId});

  final String channelId;

  @override
  List<Object> get props => [channelId];
}
