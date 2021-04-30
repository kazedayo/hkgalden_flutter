import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/repository/thread_list_repository.dart';

part 'thread_list_event.dart';
part 'thread_list_state.dart';

class ThreadListBloc extends Bloc<ThreadListEvent, ThreadListState> {
  ThreadListBloc({required ThreadListRepository repository})
      : _repository = repository,
        super(ThreadListInit());

  final ThreadListRepository _repository;

  @override
  Stream<ThreadListState> mapEventToState(ThreadListEvent event) async* {
    if (event is RequestThreadListEvent) {
      if (event.page == 1 || event.isRefresh) {
        yield ThreadListLoading();
        final List<Thread>? threads =
            await _repository.getThreadList(event.channelId, event.page);
        if (threads != null) {
          yield ThreadListLoaded(
              threads: threads,
              currentChannelId: event.channelId,
              currentPage: event.page);
        } else {
          yield ThreadListError();
        }
      } else {
        final ThreadListLoaded previousState = state as ThreadListLoaded;
        yield ThreadListAppending();
        final List<Thread>? threads =
            await _repository.getThreadList(event.channelId, event.page);
        if (threads != null) {
          yield ThreadListLoaded(
              threads: previousState.threads.toList()..addAll(threads),
              currentChannelId: event.channelId,
              currentPage: event.page);
        } else {
          add(event);
        }
      }
    }
  }
}
