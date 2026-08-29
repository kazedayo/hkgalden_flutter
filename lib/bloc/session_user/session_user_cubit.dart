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

  Future<bool> appendUserToBlockList(String userId) =>
      _setBlocked(userId, add: true);

  Future<bool> removeUserFromBlockList(String userId) =>
      _setBlocked(userId, add: false);

  Future<bool> _setBlocked(String userId, {required bool add}) async {
    if (state is! SessionUserLoaded) {
      return false;
    }
    final isSuccess =
        add ? await _api.blockUser(userId) : await _api.unblockUser(userId);
    if (isSuccess != true) {
      return false;
    }
    final sessionUser = (state as SessionUserLoaded).sessionUser;
    final List<String> blockedUsers = sessionUser.blockedUsers.toList();
    add ? blockedUsers.add(userId) : blockedUsers.remove(userId);
    emit(SessionUserLoaded(
      sessionUser: sessionUser.copyWith(blockedUsers: blockedUsers),
    ));
    return true;
  }

  void clearSessionUser() {
    emit(SessionUserUndefined());
  }
}
