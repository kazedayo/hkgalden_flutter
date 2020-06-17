import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:hkgalden_flutter/models/thread.dart';

@immutable
class ThreadState extends Equatable{
  final bool isLoading;
  final List<Thread> threads;
  final bool isRefresh;

  ThreadState({
    this.isLoading,
    this.threads,
    this.isRefresh
  });

  factory ThreadState.initial() => ThreadState(
    isLoading: true,
    threads: const [],
    isRefresh: false
  );

  ThreadState copyWith({
    bool isLoading,
    List<Thread> threads,
    bool isRefresh,
  }) {
    return ThreadState(
      isLoading: isLoading ?? this.isLoading,
      threads: threads ?? this.threads,
      isRefresh: isRefresh ?? this.isRefresh,
    );
  }

  List<Object> get props => [isLoading, threads, isRefresh];
}