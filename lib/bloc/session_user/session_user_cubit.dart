import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

part 'session_user_state.dart';

class SessionUserCubit extends Cubit<SessionUserState> {
  SessionUserCubit({required HKGaldenApi api})
      : _api = api,
        super(SessionUserUndefined());

  final HKGaldenApi _api;

  Future<void> requestSessionUser() async {
    final User? sessionUser = await _api.getSessionUserQuery();
    if (sessionUser != null) {
      emit(SessionUserLoaded(sessionUser: sessionUser));
    }
  }

  Future<void> appendUserToBlockList(String userId) async {
    if (state is SessionUserLoaded) {
      final isSuccess = await _api.blockUser(userId);
      if (isSuccess == true) {
        final List<String> blockedUsers =
            (state as SessionUserLoaded).sessionUser.blockedUsers.toList();
        blockedUsers.add(userId);
        final User updatedSessionUser = (state as SessionUserLoaded)
            .sessionUser
            .copyWith(blockedUsers: blockedUsers);
        emit(SessionUserLoaded(sessionUser: updatedSessionUser));
      }
    }
  }

  void clearSessionUser() {
    emit(SessionUserUndefined());
  }
}
