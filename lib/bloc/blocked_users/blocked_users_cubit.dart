import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

part 'blocked_users_state.dart';

class BlockedUsersCubit extends Cubit<BlockedUsersState> {
  BlockedUsersCubit({required HKGaldenApi api})
      : _api = api,
        super(BlockedUsersLoading());

  final HKGaldenApi _api;

  Future<void> load() async {
    emit(BlockedUsersLoading());
    final List<User>? blockedUsers = await _api.getBlockedUser();
    if (blockedUsers != null) {
      emit(BlockedUsersLoaded(blockedUsers: blockedUsers));
    } else {
      emit(BlockedUsersError());
    }
  }
}
