part of 'thread_bloc.dart';

abstract class ThreadState extends Equatable {
  const ThreadState();

  @override
  List<Object> get props => [];
}

class ThreadLoading extends ThreadState {}

class ThreadAppending extends ThreadState {}

class ThreadLoaded extends ThreadState {
  final Thread thread;
  final Thread previousPages;
  final int currentPage;
  final int endPage;

  const ThreadLoaded(
      {required this.thread,
      required this.previousPages,
      required this.currentPage,
      required this.endPage});

  @override
  List<Object> get props => [];
}
