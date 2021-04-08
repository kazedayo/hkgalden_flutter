import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

part 'thread_list_event.dart';
part 'thread_list_state.dart';

class ThreadListBloc extends Bloc<ThreadListEvent, ThreadListState> {
  ThreadListBloc() : super(ThreadListLoading());

  @override
  Stream<ThreadListState> mapEventToState(ThreadListEvent event) async* {
    if (event is RequestThreadListEvent) {
      if (event.page == 1) {
        yield ThreadListLoading();
        final List<Thread>? threads = await HKGaldenApi()
            .getThreadListQuery(event.channelId, event.page, event.isRefresh);
        if (threads != null) {
          yield ThreadListLoaded(
              threads: threads,
              currentChannelId: event.channelId,
              currentPage: event.page);
        }
      } else {
        final ThreadListLoaded previousState = state as ThreadListLoaded;
        yield ThreadListAppending();
        final List<Thread>? threads = await HKGaldenApi()
            .getThreadListQuery(event.channelId, event.page, event.isRefresh);
        if (threads != null) {
          yield ThreadListLoaded(
              threads: previousState.threads..addAll(threads),
              currentChannelId: event.channelId,
              currentPage: event.page);
        }
      }
    }
  }
}
