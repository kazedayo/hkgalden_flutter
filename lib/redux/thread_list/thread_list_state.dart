import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:hkgalden_flutter/models/thread.dart';

@immutable
class ThreadListState extends Equatable {
  final bool threadListIsLoading;
  final List<Thread> threads;
  final bool isRefresh;
  final String currentChannelId;
  final int currentPage;

  ThreadListState({
    this.threadListIsLoading,
    this.threads,
    this.isRefresh,
    this.currentChannelId,
    this.currentPage,
  });

  factory ThreadListState.initial() {
    return ThreadListState(
      threadListIsLoading: true,
      threads: [],
      isRefresh: false,
      currentChannelId: '',
      currentPage: 1,
    );
  }

  ThreadListState copyWith({
    bool threadListIsLoading,
    List<Thread> threads,
    bool isRefresh,
    String currentChannelId,
    int currentPage,
  }) {
    return ThreadListState(
      threadListIsLoading: threadListIsLoading ?? this.threadListIsLoading,
      threads: threads ?? this.threads,
      isRefresh: isRefresh ?? this.isRefresh,
      currentChannelId: currentChannelId ?? this.currentChannelId,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  List<Object> get props => [threadListIsLoading, threads, isRefresh, currentChannelId, currentPage];
}