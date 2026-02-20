part of 'thread_list_bloc.dart';

abstract class ThreadListState extends Equatable {
  const ThreadListState();

  @override
  List<Object> get props => [];
}

class ThreadListInit extends ThreadListState {}

class ThreadListLoading extends ThreadListState {}

class ThreadListError extends ThreadListState {}

class ThreadListAppending extends ThreadListLoaded {
  const ThreadListAppending(
      {required super.threads,
      required super.currentChannelId,
      required super.currentPage});
}

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
