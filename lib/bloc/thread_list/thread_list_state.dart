part of 'thread_list_bloc.dart';

@immutable
class ThreadListState extends Equatable {
  final bool threadListIsLoading;
  final List<Thread> threads;
  final String currentChannelId;
  final int currentPage;

  const ThreadListState({
    required this.threadListIsLoading,
    required this.threads,
    required this.currentChannelId,
    required this.currentPage,
  });

  factory ThreadListState.initial() {
    return const ThreadListState(
      threadListIsLoading: false,
      threads: [],
      currentChannelId: '',
      currentPage: 1,
    );
  }

  ThreadListState copyWith({
    bool? threadListIsLoading,
    List<Thread>? threads,
    String? currentChannelId,
    int? currentPage,
  }) {
    return ThreadListState(
      threadListIsLoading: threadListIsLoading ?? this.threadListIsLoading,
      threads: threads ?? this.threads,
      currentChannelId: currentChannelId ?? this.currentChannelId,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object> get props =>
      [threadListIsLoading, threads, currentChannelId, currentPage];
}
