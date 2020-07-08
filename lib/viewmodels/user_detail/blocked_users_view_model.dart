import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';

class BlockedUsersViewModel {
  final bool isLoading;
  final List<User> blockedUsers;

  BlockedUsersViewModel({
    this.isLoading,
    this.blockedUsers,
  });

  factory BlockedUsersViewModel.create(Store<AppState> store) =>
      BlockedUsersViewModel(
        isLoading: store.state.blockedUsersState.isLoading,
        blockedUsers: store.state.blockedUsersState.blockedUsers,
      );
}