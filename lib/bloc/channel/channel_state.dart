part of 'channel_bloc.dart';

abstract class ChannelState extends Equatable {
  const ChannelState();

  @override
  List<Object> get props => [];
}

class ChannelLoading extends ChannelState {}

class ChannelLoaded extends ChannelState {
  final List<Channel> channels;
  final String selectedChannelId;

  const ChannelLoaded(
      {required this.channels, required this.selectedChannelId});

  @override
  List<Object> get props => [channels, selectedChannelId];
}
