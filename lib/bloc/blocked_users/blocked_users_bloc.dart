import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:meta/meta.dart';

part 'blocked_users_event.dart';
part 'blocked_users_state.dart';

class BlockedUsersBloc extends Bloc<BlockedUsersEvent, BlockedUsersState> {
  BlockedUsersBloc() : super(BlockedUsersState.initial());

  @override
  Stream<BlockedUsersState> mapEventToState(BlockedUsersEvent event) async* {
    if (event is RequestBlockedUsersEvent) {
      yield state.copyWith(isLoading: true);
      final List<User>? blockedUsers = await HKGaldenApi().getBlockedUser();
      yield state.copyWith(isLoading: false, blockedUsers: blockedUsers);
    }
  }
}
