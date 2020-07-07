import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/redux/blocked_users/blocked_users_state.dart';
import 'package:hkgalden_flutter/redux/channel/channel_state.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_state.dart';
import 'package:hkgalden_flutter/redux/thread/thread_state.dart';
import 'package:hkgalden_flutter/redux/thread_list/thread_list_state.dart';
import 'package:hkgalden_flutter/redux/user_thread_list/user_thread_list_state.dart';
import 'package:meta/meta.dart';

@immutable
class AppState extends Equatable {
  final ThreadListState threadListState;
  final ThreadState threadState;
  final ChannelState channelState;
  final SessionUserState sessionUserState;
  final BlockedUsersState blockedUsersState;
  final UserThreadListState userThreadListState;

  AppState({
    @required this.threadListState,
    @required this.threadState,
    @required this.channelState,
    @required this.sessionUserState,
    @required this.blockedUsersState,
    @required this.userThreadListState,
  });

  factory AppState.initial() {
    return AppState(
      threadListState: ThreadListState.initial(),
      threadState: ThreadState.initial(),
      channelState: ChannelState.initial(),
      sessionUserState: SessionUserState.initial(),
      blockedUsersState: BlockedUsersState.initial(),
      userThreadListState: UserThreadListState.initial(),
    );
  }

  AppState copyWith(
      {ThreadListState threadListState,
      ThreadState threadState,
      ChannelState channelState,
      SessionUserState sessionUserState,
      BlockedUsersState blockedUsersState,
      UserThreadListState userThreadListState}) {
    return AppState(
      threadListState: threadListState ?? this.threadListState,
      threadState: threadState ?? this.threadState,
      channelState: channelState ?? this.channelState,
      sessionUserState: sessionUserState ?? this.sessionUserState,
      blockedUsersState: blockedUsersState ?? this.blockedUsersState,
      userThreadListState: userThreadListState ?? this.userThreadListState,
    );
  }

  List<Object> get props => [
        threadListState,
        threadState,
        channelState,
        sessionUserState,
        blockedUsersState,
        userThreadListState,
      ];
}
