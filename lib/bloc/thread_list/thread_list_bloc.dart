import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:meta/meta.dart';

part 'thread_list_event.dart';
part 'thread_list_state.dart';

class ThreadListBloc extends Bloc<ThreadListEvent, ThreadListState> {
  ThreadListBloc() : super(ThreadListState.initial());

  @override
  Stream<ThreadListState> mapEventToState(ThreadListEvent event) async* {
    if (event is RequestThreadListEvent) {
      yield state.copyWith(
          threadListIsLoading: true,
          currentPage: event.page,
          currentChannelId: event.channelId);
      final List<Thread>? threads = await HKGaldenApi()
          .getThreadListQuery(event.channelId, event.page, event.isRefresh);
      if (event.page == 1) {
        yield state.copyWith(threadListIsLoading: false, threads: threads);
      } else {
        yield state.copyWith(
            threadListIsLoading: false,
            threads: state.threads..addAll(threads!));
      }
    }
  }
}
