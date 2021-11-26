import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/repository/session_user_repository.dart';

part 'session_user_event.dart';
part 'session_user_state.dart';

class SessionUserBloc extends Bloc<SessionUserEvent, SessionUserState> {
  SessionUserBloc({required SessionUserRepository repository})
      : _repository = repository,
        super(SessionUserUndefined()) {
    on<RequestSessionUserEvent>(_onRequestSessionUserEvent);
    on<AppendUserToBlockListEvent>(_onAppendUserToBlockListEvent);
    on<RemoveSessionUserEvent>((event, emit) => emit(SessionUserUndefined()));
  }

  final SessionUserRepository _repository;

  FutureOr<void> _onRequestSessionUserEvent(
      RequestSessionUserEvent event, Emitter<SessionUserState> emit) async {
    emit(SessionUserLoading());
    final User? sessionUser = await _repository.getSessionUser();
    if (sessionUser != null) {
      emit(SessionUserLoaded(sessionUser: sessionUser));
    }
  }

  FutureOr<void> _onAppendUserToBlockListEvent(
      AppendUserToBlockListEvent event, Emitter<SessionUserState> emit) async {
    if (state is SessionUserLoaded) {
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
