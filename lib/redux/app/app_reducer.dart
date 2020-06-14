import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/thread/thread_reducer.dart';

AppState appReducer(AppState state, dynamic action) {
  return new AppState(
    threadState: threadReducer(state.threadState, action),
  );
} 