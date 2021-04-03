import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_state.dart';

part 'session_user_event.dart';

class SessionUserBloc extends Bloc<SessionUserEvent, SessionUserState> {
  SessionUserBloc() : super(SessionUserState.initial());

  @override
  Stream<SessionUserState> mapEventToState(SessionUserEvent event) async* {
    if (event is RequestSessionUserEvent) {
      yield state.copyWith(isLoading: true);
      final User? sessionUser = await HKGaldenApi().getSessionUserQuery();
      yield state.copyWith(
          isLoading: false, isLoggedIn: true, sessionUser: sessionUser);
    } else if (event is AppendUserToBlockListEvent) {
      final List<String> blockedUsers = state.sessionUser.blockedUsers.toList();
      blockedUsers.add(event.userId);
      yield state.copyWith(
          sessionUser: state.sessionUser.copyWith(blockedUsers: blockedUsers));
    } else if (event is RemoveSessionUserEvent) {
      yield SessionUserState.initial();
    }
  }
}
