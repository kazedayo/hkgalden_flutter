import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/redux/channel/channel_state.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_state.dart';
import 'package:hkgalden_flutter/redux/thread/thread_state.dart';
import 'package:hkgalden_flutter/redux/thread_list/thread_list_state.dart';
import 'package:meta/meta.dart';

@immutable
class AppState extends Equatable {
  final ThreadListState threadListState;
  final ThreadState threadState;
  final ChannelState channelState;
  final SessionUserState sessionUserState;

  AppState({
    @required this.threadListState,
    @required this.threadState,
    @required this.channelState,
    @required this.sessionUserState,
  });

  factory AppState.initial() {
    return AppState(
      threadListState: ThreadListState.initial(),
      threadState: ThreadState.initial(),
      channelState: ChannelState.initial(),
      sessionUserState: SessionUserState.initial(),
    );
  }

  AppState copyWith({
    ThreadListState threadListState,
    ThreadState threadState,
    ChannelState channelState,
    SessionUserState sessionUserState,
  }) {
    return AppState(
      threadListState: threadListState ?? this.threadListState,
      threadState: threadState ?? this.threadState,
      channelState: channelState ?? this.channelState,
      sessionUserState: sessionUserState ?? this.sessionUserState,
    );
  }

  List<Object> get props => [threadListState, threadState, channelState, sessionUserState];
}