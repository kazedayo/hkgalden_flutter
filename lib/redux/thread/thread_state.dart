import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:hkgalden_flutter/models/thread.dart';

@immutable
class ThreadState extends Equatable {
  final bool threadIsLoading;
  final Thread thread;
  final int currentPage;
  final bool isInitialLoad;

  ThreadState({
    this.threadIsLoading,
    this.thread,
    this.currentPage,
    this.isInitialLoad
  });

  factory ThreadState.initial() => ThreadState(
    threadIsLoading: true,
    thread: Thread(),
    currentPage: 1,
    isInitialLoad: true,
  );

  ThreadState copyWith({
    bool threadIsLoading,
    Thread thread,
    int currentPage,
    bool isInitialLoad,
  }) {
    return ThreadState(
      threadIsLoading: threadIsLoading ?? this.threadIsLoading,
      thread: thread ?? this.thread,
      currentPage: currentPage ?? this.currentPage,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
    );
  }

  List<Object> get props => [threadIsLoading, thread, currentPage, isInitialLoad];
}