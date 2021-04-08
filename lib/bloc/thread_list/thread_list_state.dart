part of 'thread_list_bloc.dart';

class ThreadListState extends Equatable {
  const ThreadListState();

  @override
  List<Object> get props => [];
}

class ThreadListLoading extends ThreadListState {}

class ThreadListAppending extends ThreadListState {}

class ThreadListLoaded extends ThreadListState {
  final List<Thread> threads;
  final String currentChannelId;
  final int currentPage;

  const ThreadListLoaded(
      {required this.threads,
      required this.currentChannelId,
      required this.currentPage});

  @override
  List<Object> get props => [threads, currentChannelId, currentPage];
}
