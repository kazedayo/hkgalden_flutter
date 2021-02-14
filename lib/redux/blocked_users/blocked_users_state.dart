import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:meta/meta.dart';

@immutable
class BlockedUsersState extends Equatable {
  final bool isLoading;
  final List<User> blockedUsers;

  const BlockedUsersState({this.isLoading, this.blockedUsers});

  factory BlockedUsersState.initial() => const BlockedUsersState(
        isLoading: true,
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

  @override
  List<Object> get props => [isLoading, blockedUsers];
}
