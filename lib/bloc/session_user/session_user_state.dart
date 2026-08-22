part of 'session_user_cubit.dart';

abstract class SessionUserState extends Equatable {
  const SessionUserState();

  @override
  List<Object> get props => [];
}

class SessionUserUndefined extends SessionUserState {}

class SessionUserLoaded extends SessionUserState {
  final User sessionUser;

  const SessionUserLoaded({required this.sessionUser});

  @override
  List<Object> get props => [sessionUser];
}
