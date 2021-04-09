part of 'session_user_bloc.dart';

abstract class SessionUserState extends Equatable {
  const SessionUserState();

  @override
  List<Object> get props => [];
}

class SessionUserLoading extends SessionUserState {}

class SessionUserUndefined extends SessionUserState {}

class SessionUserLoaded extends SessionUserState {
  final User sessionUser;

  const SessionUserLoaded({required this.sessionUser});

  @override
  List<Object> get props => [sessionUser];
}
