import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';

class BlockedUsersViewModel extends Equatable {
  final bool isLoading;
  final List<User> blockedUsers;

  const BlockedUsersViewModel({
    required this.isLoading,
    required this.blockedUsers,
  });

  factory BlockedUsersViewModel.create(Store<AppState> store) =>
      BlockedUsersViewModel(
        isLoading: store.state.blockedUsersState.isLoading,
        blockedUsers: store.state.blockedUsersState.blockedUsers,
      );

  @override
  List<Object> get props => [isLoading, blockedUsers];
}
