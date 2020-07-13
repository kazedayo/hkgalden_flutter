import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:hkgalden_flutter/models/user.dart';

@immutable
class SessionUserState extends Equatable {
  final bool isLoading;
  final bool isLoggedIn;
  final User sessionUser;

  SessionUserState({
    this.isLoading,
    this.isLoggedIn,
    this.sessionUser,
  });

  factory SessionUserState.initial() => SessionUserState(
        isLoading: false,
        isLoggedIn: false,
        sessionUser: User(
          userId: '',
          nickName: '',
          avatar: '',
          userGroup: [],
          blockedUsers: [],
        ),
      );

  SessionUserState copyWith({
    bool isLoading,
    bool isLoggedIn,
    User sessionUser,
  }) {
    return SessionUserState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      sessionUser: sessionUser ?? this.sessionUser,
    );
  }

  List<Object> get props => [isLoading, isLoggedIn, sessionUser];
}
