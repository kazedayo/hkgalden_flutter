import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

part 'blocked_users_event.dart';
part 'blocked_users_state.dart';

class BlockedUsersBloc extends Bloc<BlockedUsersEvent, BlockedUsersState> {
  BlockedUsersBloc({required HKGaldenApi api})
      : _api = api,
        super(BlockedUsersLoading()) {
    on<RequestBlockedUsersEvent>(_onRequestBlockedUsersEvent);
  }

  final HKGaldenApi _api;

  FutureOr<void> _onRequestBlockedUsersEvent(
      RequestBlockedUsersEvent event, Emitter<BlockedUsersState> emit) async {
    emit(BlockedUsersLoading());
    final List<User>? blockedUsers = await _api.getBlockedUser();
    if (blockedUsers != null) {
      emit(BlockedUsersLoaded(blockedUsers: blockedUsers));
    } else {
      emit(BlockedUsersError());
    }
  }
}
