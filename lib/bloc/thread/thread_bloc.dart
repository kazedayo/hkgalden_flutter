import 'dart:async';

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
        super(ThreadInit()) {
    on<RequestThreadEvent>(_onRequestThreadEvent);
    on<AppendReplyToThreadEvent>(_onAppendReplyToThreadEvent);
    on<ClearThreadStateEvent>((event, emit) => emit(ThreadInit()));
  }

  final ThreadRepository _repository;

  FutureOr<void> _onRequestThreadEvent(
      RequestThreadEvent event, Emitter<ThreadState> emit) async {
    if (event.isInitialLoad) {
      emit(ThreadLoading());
      final Thread? thread =
          await _repository.getThread(event.threadId, event.page);
      if (thread != null) {
        emit(ThreadLoaded(
            thread: thread,
            previousPages: Thread.initial(),
            currentPage: event.page,
            endPage: event.page));
      } else {
        emit(ThreadError());
      }
    } else {
      final ThreadLoaded previousState = state as ThreadLoaded;
      emit(ThreadAppending());
      final Thread? thread =
          await _repository.getThread(event.threadId, event.page);
      if (thread != null) {
        if (event.page < previousState.endPage) {
          emit(ThreadLoaded(
              thread: previousState.thread,
              previousPages: thread.copyWith(
                  replies: thread.replies.toList()
                    ..addAll(previousState.previousPages.replies),
                  totalReplies: thread.totalReplies),
              currentPage: event.page,
              endPage: previousState.endPage));
        } else {
          emit(ThreadLoaded(
              thread: previousState.thread.copyWith(
                  replies: event.page == previousState.endPage
                      ? thread.replies
                      : (previousState.thread.replies.toList()
                        ..addAll(thread.replies))),
              previousPages: previousState.previousPages,
              currentPage: event.page,
              endPage: event.page));
        }
      } else {
        emit(ThreadError());
      }
    }
  }

  FutureOr<void> _onAppendReplyToThreadEvent(
      AppendReplyToThreadEvent event, Emitter<ThreadState> emit) async {
    if (state is ThreadLoaded) {
      final ThreadLoaded previousState = state as ThreadLoaded;
      emit(ThreadAppending());
      final List<Reply> replies = previousState.thread.replies.toList();
      replies.add(event.reply);
      emit(ThreadLoaded(
          thread: previousState.thread.copyWith(replies: replies),
          previousPages: previousState.previousPages,
          currentPage: previousState.currentPage,
          endPage: previousState.endPage));
    }
  }
}
