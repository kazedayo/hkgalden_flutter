part of 'blocked_users_bloc.dart';

abstract class BlockedUsersEvent extends Equatable {
  const BlockedUsersEvent();

  @override
  List<Object> get props => [];
}

class RequestBlockedUsersEvent extends BlockedUsersEvent {}
