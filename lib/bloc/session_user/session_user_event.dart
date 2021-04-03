part of 'session_user_bloc.dart';

abstract class SessionUserEvent extends Equatable {
  const SessionUserEvent();

  @override
  List<Object> get props => [];
}

class RequestSessionUserEvent extends SessionUserEvent {}

class AppendUserToBlockListEvent extends SessionUserEvent {
  final String userId;

  const AppendUserToBlockListEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class RemoveSessionUserEvent extends SessionUserEvent {}
