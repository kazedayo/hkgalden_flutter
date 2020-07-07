import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:meta/meta.dart';

@immutable
class BlockedUsersState extends Equatable {
  final bool isLoading;
  final List<User> blockedUsers;

  BlockedUsersState({this.isLoading, this.blockedUsers});

  factory BlockedUsersState.initial() => BlockedUsersState(
        isLoading: false,
        blockedUsers: [],
      );

  BlockedUsersState copyWith({
    bool isLoading,
    List<User> blockedUsers,
  }) =>
      BlockedUsersState(
        isLoading: isLoading ?? this.isLoading,
        blockedUsers: blockedUsers ?? this.blockedUsers,
      );

  List<Object> get props => [isLoading, blockedUsers];
}
