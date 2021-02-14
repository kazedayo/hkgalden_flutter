import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:hkgalden_flutter/models/channel.dart';

@immutable
class ChannelState extends Equatable {
  final bool isLoading;
  final List<Channel> channels;
  final String selectedChannelId;

  const ChannelState({
    this.isLoading,
    this.channels,
    this.selectedChannelId,
  });

  factory ChannelState.initial() => const ChannelState(
        isLoading: false,
        channels: [],
        selectedChannelId: 'bw',
      );

  ChannelState copyWith({
    bool isLoading,
    List<Channel> channels,
    String selectedChannelId,
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
