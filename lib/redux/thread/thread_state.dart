import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:hkgalden_flutter/models/thread.dart';

@immutable
class ThreadState extends Equatable {
  final bool threadIsLoading;
  final Thread thread;
  final Thread previousPages;
  final int currentPage;
  final int endPage;
  final bool isInitialLoad;

  const ThreadState(
      {this.threadIsLoading,
      this.thread,
      this.previousPages,
      this.currentPage,
      this.endPage,
      this.isInitialLoad});

  factory ThreadState.initial() => ThreadState(
        threadIsLoading: false,
        thread: Thread.initial(),
        previousPages: Thread.initial(),
        currentPage: 1,
        endPage: 1,
        isInitialLoad: true,
      );

  ThreadState copyWith({
    bool threadIsLoading,
    Thread thread,
    Thread previousPages,
    int currentPage,
    int endPage,
    bool isInitialLoad,
  }) {
    return ThreadState(
      threadIsLoading: threadIsLoading ?? this.threadIsLoading,
      thread: thread ?? this.thread,
      previousPages: previousPages ?? this.previousPages,
      currentPage: currentPage ?? this.currentPage,
      endPage: endPage ?? this.endPage,
      isInitialLoad: isInitialLoad ?? this.isInitialLoad,
    );
  }

  @override
  List<Object> get props => [
        threadIsLoading,
        thread,
        previousPages,
        currentPage,
        endPage,
        isInitialLoad
      ];
}
