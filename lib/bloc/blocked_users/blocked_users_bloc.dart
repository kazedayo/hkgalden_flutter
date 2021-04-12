import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/repository/blocked_users_repository.dart';

part 'blocked_users_event.dart';
part 'blocked_users_state.dart';

class BlockedUsersBloc extends Bloc<BlockedUsersEvent, BlockedUsersState> {
  BlockedUsersBloc({required BlockedUsersRepository repository}) : _repository = repository ,super(BlockedUsersLoading());

  final BlockedUsersRepository _repository;

  @override
  Stream<BlockedUsersState> mapEventToState(BlockedUsersEvent event) async* {
    if (event is RequestBlockedUsersEvent) {
      final List<User>? blockedUsers = await _repository.getBlockedUsers();
      if (blockedUsers != null) {
        yield BlockedUsersLoaded(blockedUsers: blockedUsers);
      }
    }
  }
}
