import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:meta/meta.dart';

part 'thread_event.dart';
part 'thread_state.dart';

class ThreadBloc extends Bloc<ThreadEvent, ThreadState> {
  ThreadBloc() : super(ThreadState.initial());

  @override
  Stream<ThreadState> mapEventToState(ThreadEvent event) async* {
    if (event is RequestThreadEvent) {
      yield state.copyWith(
          threadIsLoading: true, isInitialLoad: event.isInitialLoad);
      final Thread? thread = await HKGaldenApi()
          .getThreadQuery(event.threadId, event.page, event.isInitialLoad);
      if (event.isInitialLoad) {
        yield state.copyWith(
            threadIsLoading: false,
            thread: thread,
            isInitialLoad: false,
            currentPage: event.page,
            endPage: event.page);
      } else {
        if (event.page < state.endPage) {
          yield state.copyWith(
              threadIsLoading: false,
              previousPages: thread!.copyWith(
                  replies: thread.replies..addAll(state.previousPages.replies),
                  totalReplies: thread.totalReplies),
              isInitialLoad: false,
              currentPage: event.page);
        } else {
          yield state.copyWith(
              threadIsLoading: false,
              thread: state.thread.copyWith(
                  replies: event.page == state.endPage
                      ? thread!.replies
                      : (state.thread.replies..addAll(thread!.replies)),
                  totalReplies: thread.totalReplies),
              isInitialLoad: false,
              currentPage: event.page,
              endPage: event.page);
        }
      }
    } else if (event is AppendReplyToThreadEvent) {
      final List<Reply> replies = state.thread.replies.toList();
      replies.add(event.reply);
      yield state.copyWith(thread: state.thread.copyWith(replies: replies));
    } else if (event is ClearThreadStateEvent) {
      yield ThreadState.initial();
    }
  }
}
