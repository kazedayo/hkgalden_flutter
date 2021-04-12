import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/repository/session_user_repository.dart';

part 'session_user_event.dart';
part 'session_user_state.dart';

class SessionUserBloc extends Bloc<SessionUserEvent, SessionUserState> {
  SessionUserBloc({required SessionUserRepository repository})
      : _repository = repository,
        super(SessionUserUndefined());

  final SessionUserRepository _repository;

  @override
  Stream<SessionUserState> mapEventToState(SessionUserEvent event) async* {
    if (event is RequestSessionUserEvent) {
      yield SessionUserLoading();
      final User? sessionUser = await _repository.getSessionUser();
      if (sessionUser != null) {
        yield SessionUserLoaded(sessionUser: sessionUser);
      }
    } else if (event is AppendUserToBlockListEvent) {
      if (state is SessionUserLoaded) {
        final List<String> blockedUsers =
            (state as SessionUserLoaded).sessionUser.blockedUsers.toList();
        blockedUsers.add(event.userId);
        final User updatedSessionUser = (state as SessionUserLoaded)
            .sessionUser
            .copyWith(blockedUsers: blockedUsers);
        yield SessionUserLoaded(sessionUser: updatedSessionUser);
      }
    } else if (event is RemoveSessionUserEvent) {
      yield SessionUserUndefined();
    }
  }
}
