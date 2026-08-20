import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

part 'session_user_event.dart';
part 'session_user_state.dart';

class SessionUserBloc extends Bloc<SessionUserEvent, SessionUserState> {
  SessionUserBloc({required HKGaldenApi api})
      : _api = api,
        super(SessionUserUndefined()) {
    on<RequestSessionUserEvent>(_onRequestSessionUserEvent);
    on<AppendUserToBlockListEvent>(_onAppendUserToBlockListEvent);
    on<RemoveSessionUserEvent>((event, emit) => emit(SessionUserUndefined()));
  }

  final HKGaldenApi _api;

  FutureOr<void> _onRequestSessionUserEvent(
      RequestSessionUserEvent event, Emitter<SessionUserState> emit) async {
    emit(SessionUserLoading());
    final User? sessionUser = await _api.getSessionUserQuery();
    if (sessionUser != null) {
      emit(SessionUserLoaded(sessionUser: sessionUser));
    }
  }

  FutureOr<void> _onAppendUserToBlockListEvent(
      AppendUserToBlockListEvent event, Emitter<SessionUserState> emit) async {
    if (state is SessionUserLoaded) {
      final isSuccess = await _api.blockUser(event.userId);
      if (isSuccess == true) {
        final List<String> blockedUsers =
            (state as SessionUserLoaded).sessionUser.blockedUsers.toList();
        blockedUsers.add(event.userId);
        final User updatedSessionUser = (state as SessionUserLoaded)
            .sessionUser
            .copyWith(blockedUsers: blockedUsers);
        emit(SessionUserLoaded(sessionUser: updatedSessionUser));
      }
    }
  }
}
