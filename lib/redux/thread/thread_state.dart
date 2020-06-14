import 'package:meta/meta.dart';
import 'package:hkgalden_flutter/models/thread.dart';

@immutable
class ThreadState {
  final bool isLoading;
  final List<Thread> threads;

  ThreadState({
    this.isLoading,
    this.threads
  });

  factory ThreadState.initial() => ThreadState(
    isLoading: false,
    threads: const []
  );

  ThreadState copyWith({
    bool isLoading,
    List<Thread> threads
  }) {
    return ThreadState(
      isLoading: isLoading ?? this.isLoading,
      threads: threads ?? this.threads
    );
  }
}