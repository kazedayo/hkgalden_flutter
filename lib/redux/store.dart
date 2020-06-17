import 'package:hkgalden_flutter/redux/app/app_reducer.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/channel/channel_middleware.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_middleware.dart';
import 'package:hkgalden_flutter/redux/thread/thread_middleware.dart';
import 'package:redux/redux.dart';

final Store<AppState> store = Store(
  appReducer,
  initialState: AppState.initial(),
  distinct: true,
  middleware: [
    ThreadMiddleware(),
    ChannelMiddleware(),
    SessionUserMiddleware(),
  ],
);