part of 'thread_cubit.dart';

abstract class ThreadState extends Equatable {
  const ThreadState();

  @override
  List<Object> get props => [];
}

class ThreadLoading extends ThreadState {}

class ThreadError extends ThreadState {}

class ThreadAppending extends ThreadState {}

class ThreadLoaded extends ThreadState {
  final Thread thread;
  final List<Reply> previousReplies;
  final int currentPage;
  final int endPage;

  const ThreadLoaded(
      {required this.thread,
      required this.previousReplies,
      required this.currentPage,
      required this.endPage});

  @override
  List<Object> get props => [thread, previousReplies, currentPage, endPage];
}
