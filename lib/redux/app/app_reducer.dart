import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_reducer.dart';
import 'package:hkgalden_flutter/redux/thread/thread_reducer.dart';
import 'package:hkgalden_flutter/redux/channel/channel_reducer.dart';
import 'package:hkgalden_flutter/redux/thread_list/thread_list_reducer.dart';

AppState appReducer(AppState state, dynamic action) {
  return new AppState(
    threadListState: threadListReducer(state.threadListState, action),
    threadState: threadReducer(state.threadState, action),
    channelState: channelReducer(state.channelState, action),
    sessionUserState: sessionUserReducer(state.sessionUserState, action),
  );
} 