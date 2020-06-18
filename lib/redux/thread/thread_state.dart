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
  final String currentChannelId;
  final int currentPage;

  ThreadState({
    this.threadListIsLoading,
    this.threadIsLoading,
    this.threads,
    this.thread,
    this.isRefresh,
    this.currentChannelId,
    this.currentPage,
  });

  factory ThreadState.initial() => ThreadState(
    threadListIsLoading: true,
    threadIsLoading: true,
    threads: [],
    thread: Thread(),
    isRefresh: false,
    currentChannelId: '',
    currentPage: 1,
  );

  ThreadState copyWith({
    bool threadListIsLoading,
    bool threadIsLoading,
    List<Thread> threads,
    Thread thread,
    bool isRefresh,
    String currentChannelId,
    int currentPage,
  }) {
    return ThreadState(
      threadListIsLoading: threadListIsLoading ?? this.threadListIsLoading,
      threadIsLoading: threadIsLoading ?? this.threadIsLoading,
      threads: threads ?? this.threads,
      thread: thread ?? this.thread,
      isRefresh: isRefresh ?? this.isRefresh,
      currentChannelId: currentChannelId ?? this.currentChannelId,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  List<Object> get props => [threadListIsLoading, threadIsLoading, threads, thread, isRefresh, currentChannelId, currentPage];
}