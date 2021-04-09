import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

part 'thread_event.dart';
part 'thread_state.dart';

class ThreadBloc extends Bloc<ThreadEvent, ThreadState> {
  ThreadBloc() : super(ThreadLoading());

  @override
  Stream<ThreadState> mapEventToState(ThreadEvent event) async* {
    if (event is RequestThreadEvent) {
      if (event.isInitialLoad) {
        final Thread? thread = await HKGaldenApi()
            .getThreadQuery(event.threadId, event.page, event.isInitialLoad);
        if (thread != null) {
          yield ThreadLoaded(
              thread: thread,
              previousPages: Thread.initial(),
              currentPage: event.page,
              endPage: event.page);
        }
      } else {
        final ThreadLoaded previousState = state as ThreadLoaded;
        yield ThreadAppending();
        final Thread? thread = await HKGaldenApi()
            .getThreadQuery(event.threadId, event.page, event.isInitialLoad);
        if (thread != null) {
          if (event.page < previousState.endPage) {
            yield ThreadLoaded(
                thread: previousState.thread,
                previousPages: thread.copyWith(
                    replies: thread.replies
                      ..addAll(previousState.previousPages.replies),
                    totalReplies: thread.totalReplies),
                currentPage: event.page,
                endPage: previousState.endPage);
          } else {
            yield ThreadLoaded(
                thread: previousState.thread.copyWith(
                    replies: event.page == previousState.endPage
                        ? thread.replies
                        : (previousState.thread.replies
                          ..addAll(thread.replies))),
                previousPages: previousState.previousPages,
                currentPage: event.page,
                endPage: event.page);
          }
        }
      }
    } else if (event is AppendReplyToThreadEvent) {
      if (state is ThreadLoaded) {
        final List<Reply> replies =
            (state as ThreadLoaded).thread.replies.toList();
        replies.add(event.reply);
        yield ThreadLoaded(
            thread: (state as ThreadLoaded).thread.copyWith(replies: replies),
            previousPages: (state as ThreadLoaded).previousPages,
            currentPage: (state as ThreadLoaded).currentPage,
            endPage: (state as ThreadLoaded).endPage);
      }
    } else if (event is ClearThreadStateEvent) {
      yield ThreadLoading();
    }
  }
}
