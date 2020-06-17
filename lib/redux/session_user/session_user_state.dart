import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:hkgalden_flutter/models/session_user.dart';

@immutable
class SessionUserState extends Equatable{
  final bool isLoading;
  final SessionUser sessionUser;

  SessionUserState({
    this.isLoading,
    this.sessionUser,
  });

  factory SessionUserState.initial() => SessionUserState(
    isLoading: false,
    sessionUser: SessionUser(
      userId: '',
      nickName: '',
      avatar: '',
      userGroup: [],
    ),
  );

  SessionUserState copyWith({
    bool isLoading,
    SessionUser sessionUser,
  }) {
    return SessionUserState(
      isLoading: isLoading ?? this.isLoading,
      sessionUser: sessionUser ?? this.sessionUser,
    );
  }

  List<Object> get props => [isLoading, sessionUser];
}