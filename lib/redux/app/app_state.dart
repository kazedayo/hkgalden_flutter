import 'package:hkgalden_flutter/redux/channel/channel_state.dart';
import 'package:hkgalden_flutter/redux/thread/thread_state.dart';
import 'package:meta/meta.dart';

@immutable
class AppState {
  final ThreadState threadState;
  final ChannelState channelState;

  AppState({
    @required this.threadState,
    @required this.channelState,
  });

  factory AppState.initial() {
    return AppState(
      threadState: ThreadState.initial(),
      channelState: ChannelState.initial(),
    );
  }

  AppState copyWith({
    ThreadState threadState
  }) {
    return AppState(
      threadState: threadState ?? this.threadState,
      channelState: channelState ?? this.channelState,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other)||
      other is AppState && 
          runtimeType == other.runtimeType &&
          threadState == other.threadState && 
          channelState == other.channelState;

  @override
  int get hashCode => 
      threadState.hashCode ^ 
      channelState.hashCode;
}