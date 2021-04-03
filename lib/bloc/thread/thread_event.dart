part of 'thread_bloc.dart';

class ThreadEvent extends Equatable {
  const ThreadEvent();

  @override
  List<Object> get props => [];
}

class RequestThreadEvent extends ThreadEvent {
  final int threadId;
  final int page;
  final bool isInitialLoad;

  const RequestThreadEvent(
      {required this.threadId,
      required this.page,
      required this.isInitialLoad});

  @override
  List<Object> get props => [threadId, page, isInitialLoad];
}

class AppendReplyToThreadEvent extends ThreadEvent {
  final Reply reply;

  const AppendReplyToThreadEvent({required this.reply});

  @override
  List<Object> get props => [reply];
}

class ClearThreadStateEvent extends ThreadEvent {}
