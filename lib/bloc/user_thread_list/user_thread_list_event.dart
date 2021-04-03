part of 'user_thread_list_bloc.dart';

abstract class UserThreadListEvent extends Equatable {
  const UserThreadListEvent();

  @override
  List<Object> get props => [];
}

class RequestUserThreadListEvent extends UserThreadListEvent {
  final String userId;
  final int page;

  const RequestUserThreadListEvent({required this.userId, required this.page});

  @override
  List<Object> get props => [userId, page];
}
