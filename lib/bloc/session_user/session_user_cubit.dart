import 'package:flutter_bloc/flutter_bloc.dart';
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

  Future<bool> appendUserToBlockList(String userId) async {
    if (state is! SessionUserLoaded) {
      return false;
    }
    final isSuccess = await _api.blockUser(userId);
    if (isSuccess != true) {
      return false;
    }
    final List<String> blockedUsers =
        (state as SessionUserLoaded).sessionUser.blockedUsers.toList()
          ..add(userId);
    emit(SessionUserLoaded(
      sessionUser: (state as SessionUserLoaded)
          .sessionUser
          .copyWith(blockedUsers: blockedUsers),
    ));
    return true;
  }

  Future<bool> removeUserFromBlockList(String userId) async {
    if (state is! SessionUserLoaded) {
      return false;
    }
    final isSuccess = await _api.unblockUser(userId);
    if (isSuccess != true) {
      return false;
    }
    final List<String> blockedUsers =
        (state as SessionUserLoaded).sessionUser.blockedUsers.toList()
          ..remove(userId);
    emit(SessionUserLoaded(
      sessionUser: (state as SessionUserLoaded)
          .sessionUser
          .copyWith(blockedUsers: blockedUsers),
    ));
    return true;
  }

  void clearSessionUser() {
    emit(SessionUserUndefined());
  }
}
