import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/repository/blocked_users_repository.dart';

part 'blocked_users_event.dart';
part 'blocked_users_state.dart';

class BlockedUsersBloc extends Bloc<BlockedUsersEvent, BlockedUsersState> {
  BlockedUsersBloc({required BlockedUsersRepository repository})
      : _repository = repository,
        super(BlockedUsersLoading()) {
    on<RequestBlockedUsersEvent>(_onRequestBlockedUsersEvent);
  }

  final BlockedUsersRepository _repository;

  FutureOr<void> _onRequestBlockedUsersEvent(
      RequestBlockedUsersEvent event, Emitter<BlockedUsersState> emit) async {
    final List<User>? blockedUsers = await _repository.getBlockedUsers();
    if (blockedUsers != null) {
      emit(BlockedUsersLoaded(blockedUsers: blockedUsers));
    }
  }
}
