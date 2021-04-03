part of 'channel_bloc.dart';

@immutable
class ChannelState extends Equatable {
  final bool isLoading;
  final List<Channel> channels;
  final String selectedChannelId;

  const ChannelState({
    required this.isLoading,
    required this.channels,
    required this.selectedChannelId,
  });

  factory ChannelState.initial() => const ChannelState(
        isLoading: false,
        channels: [],
        selectedChannelId: 'bw',
      );

  ChannelState copyWith({
    bool? isLoading,
    List<Channel>? channels,
    String? selectedChannelId,
  }) {
    return ChannelState(
      isLoading: isLoading ?? this.isLoading,
      channels: channels ?? this.channels,
      selectedChannelId: selectedChannelId ?? this.selectedChannelId,
    );
  }

  @override
  List<Object> get props => [isLoading, channels, selectedChannelId];
}
