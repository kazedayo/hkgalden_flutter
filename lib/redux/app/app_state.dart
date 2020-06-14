import 'package:hkgalden_flutter/redux/thread/thread_state.dart';
import 'package:meta/meta.dart';

@immutable
class AppState {
  final ThreadState threadState;

  AppState({
    @required this.threadState,
  });

  factory AppState.initial() {
    return AppState(
      threadState: ThreadState.initial(),
    );
  }

  AppState copyWith({
    ThreadState threadState
  }) {
    return AppState(
      threadState: threadState ?? this.threadState,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other)||
      other is AppState && 
          runtimeType == other.runtimeType &&
          threadState == other.threadState;

  @override
  int get hashCode => 
      threadState.hashCode;
}