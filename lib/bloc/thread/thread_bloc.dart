import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/repository/thread_repository.dart';

part 'thread_event.dart';
part 'thread_state.dart';

class ThreadBloc extends Bloc<ThreadEvent, ThreadState> {
  ThreadBloc({required ThreadRepository repository})
      : _repository = repository,
        super(ThreadLoading());

  final ThreadRepository _repository;

  @override
  Stream<ThreadState> mapEventToState(ThreadEvent event) async* {
    if (event is RequestThreadEvent) {
      if (event.isInitialLoad) {
        final Thread? thread =
            await _repository.getThread(event.threadId, event.page);
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
        final Thread? thread =
            await _repository.getThread(event.threadId, event.page);
        if (thread != null) {
          if (event.page < previousState.endPage) {
            yield ThreadLoaded(
                thread: previousState.thread,
                previousPages: thread.copyWith(
                    replies: thread.replies.toList()
                      ..addAll(previousState.previousPages.replies),
                    totalReplies: thread.totalReplies),
                currentPage: event.page,
                endPage: previousState.endPage);
          } else {
            yield ThreadLoaded(
                thread: previousState.thread.copyWith(
                    replies: event.page == previousState.endPage
                        ? thread.replies
                        : (previousState.thread.replies.toList()
                          ..addAll(thread.replies))),
                previousPages: previousState.previousPages,
                currentPage: event.page,
                endPage: event.page);
          }
        }
      }
    } else if (event is AppendReplyToThreadEvent) {
      if (state is ThreadLoaded) {
        final ThreadLoaded previousState = state as ThreadLoaded;
        yield ThreadAppending();
        final List<Reply> replies = previousState.thread.replies.toList();
        replies.add(event.reply);
        yield ThreadLoaded(
            thread: previousState.thread.copyWith(replies: replies),
            previousPages: previousState.previousPages,
            currentPage: previousState.currentPage,
            endPage: previousState.endPage);
      }
    } else if (event is ClearThreadStateEvent) {
      yield ThreadLoading();
    }
  }
}
