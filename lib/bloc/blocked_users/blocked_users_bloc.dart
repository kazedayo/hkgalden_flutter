import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

part 'blocked_users_event.dart';
part 'blocked_users_state.dart';

class BlockedUsersBloc extends Bloc<BlockedUsersEvent, BlockedUsersState> {
  BlockedUsersBloc() : super(BlockedUsersLoading());

  @override
  Stream<BlockedUsersState> mapEventToState(BlockedUsersEvent event) async* {
    if (event is RequestBlockedUsersEvent) {
      final List<User>? blockedUsers = await HKGaldenApi().getBlockedUser();
      if (blockedUsers != null) {
        yield BlockedUsersLoaded(blockedUsers: blockedUsers);
      }
    }
  }
}
