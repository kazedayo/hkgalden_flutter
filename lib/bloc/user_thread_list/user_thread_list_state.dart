part of 'user_thread_list_bloc.dart';

abstract class UserThreadListState extends Equatable {
  const UserThreadListState();

  @override
  List<Object> get props => [];
}

class UserThreadListLoading extends UserThreadListState {}

class UserThreadListLoaded extends UserThreadListState {
  final int page;
  final List<Thread> userThreadList;

  const UserThreadListLoaded(
      {required this.page, required this.userThreadList});

  @override
  List<Object> get props => [page, userThreadList];
}
