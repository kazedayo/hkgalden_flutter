part of 'blocked_users_cubit.dart';

abstract class BlockedUsersState extends Equatable {
  const BlockedUsersState();

  @override
  List<Object> get props => [];
}

class BlockedUsersLoading extends BlockedUsersState {}

class BlockedUsersError extends BlockedUsersState {}

class BlockedUsersLoaded extends BlockedUsersState {
  final List<User> blockedUsers;

  const BlockedUsersLoaded({required this.blockedUsers});

  @override
  List<Object> get props => [blockedUsers];
}
