import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:hkgalden_flutter/models/user.dart';

@immutable
class SessionUserState extends Equatable {
  final bool isLoading;
  final bool isLoggedIn;
  final User sessionUser;

  const SessionUserState({
    required this.isLoading,
    required this.isLoggedIn,
    required this.sessionUser,
  });

  factory SessionUserState.initial() => const SessionUserState(
        isLoading: false,
        isLoggedIn: false,
        sessionUser: User(
          userId: '',
          nickName: '',
          avatar: '',
          userGroup: [],
          blockedUsers: [],
          gender: '',
        ),
      );

  SessionUserState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    User? sessionUser,
  }) {
    return SessionUserState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      sessionUser: sessionUser ?? this.sessionUser,
    );
  }

  @override
  List<Object> get props => [isLoading, isLoggedIn, sessionUser];
}
