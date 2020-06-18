import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:hkgalden_flutter/models/thread.dart';

@immutable
class ThreadState extends Equatable{
  final bool threadListIsLoading;
  final bool threadIsLoading;
  final List<Thread> threads;
  final Thread thread;
  final bool isRefresh;

  ThreadState({
    this.threadListIsLoading,
    this.threadIsLoading,
    this.threads,
    this.thread,
    this.isRefresh
  });

  factory ThreadState.initial() => ThreadState(
    threadListIsLoading: true,
    threadIsLoading: true,
    threads: const [],
    thread: Thread(),
    isRefresh: false
  );

  ThreadState copyWith({
    bool threadListIsLoading,
    bool threadIsLoading,
    List<Thread> threads,
    Thread thread,
    bool isRefresh,
  }) {
    return ThreadState(
      threadListIsLoading: threadListIsLoading ?? this.threadListIsLoading,
      threadIsLoading: threadIsLoading ?? this.threadIsLoading,
      threads: threads ?? this.threads,
      thread: thread ?? this.thread,
      isRefresh: isRefresh ?? this.isRefresh,
    );
  }

  List<Object> get props => [threadListIsLoading, threadIsLoading, threads, thread, isRefresh];
}