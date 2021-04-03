part of 'thread_list_bloc.dart';

abstract class ThreadListEvent extends Equatable {
  const ThreadListEvent();

  @override
  List<Object> get props => [];
}

class RequestThreadListEvent extends ThreadListEvent {
  final String channelId;
  final int page;
  final bool isRefresh;

  const RequestThreadListEvent(
      {required this.channelId, required this.page, required this.isRefresh});

  @override
  List<Object> get props => [channelId, page, isRefresh];
}
