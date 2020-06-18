import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:hkgalden_flutter/models/user.dart';

@immutable
class SessionUserState extends Equatable{
  final bool isLoading;
  final User sessionUser;

  SessionUserState({
    this.isLoading,
    this.sessionUser,
  });

  factory SessionUserState.initial() => SessionUserState(
    isLoading: false,
    sessionUser: User(
      userId: '',
      nickName: '',
      avatar: '',
      userGroup: null,
    ),
  );

  SessionUserState copyWith({
    bool isLoading,
    User sessionUser,
  }) {
    return SessionUserState(
      isLoading: isLoading ?? this.isLoading,
      sessionUser: sessionUser ?? this.sessionUser,
    );
  }

  List<Object> get props => [isLoading, sessionUser];
}