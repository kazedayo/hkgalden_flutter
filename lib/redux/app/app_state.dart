import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/redux/channel/channel_state.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_state.dart';
import 'package:hkgalden_flutter/redux/thread/thread_state.dart';
import 'package:meta/meta.dart';

@immutable
class AppState extends Equatable {
  final ThreadState threadState;
  final ChannelState channelState;
  final SessionUserState sessionUserState;

  AppState({
    @required this.threadState,
    @required this.channelState,
    @required this.sessionUserState,
  });

  factory AppState.initial() {
    return AppState(
      threadState: ThreadState.initial(),
      channelState: ChannelState.initial(),
      sessionUserState: SessionUserState.initial(),
    );
  }

  AppState copyWith({
    ThreadState threadState
  }) {
    return AppState(
      threadState: threadState ?? this.threadState,
      channelState: channelState ?? this.channelState,
      sessionUserState: sessionUserState ?? this.sessionUserState,
    );
  }

  List<Object> get props => [threadState, channelState, sessionUserState];
}