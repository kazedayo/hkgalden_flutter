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
      // Ignore pagination while loading/appending/error — avoids cast crashes
      // when the scroll listener queues multiple RequestThreadEvent before the
      // first emit(ThreadAppending) runs.
      final current = state;
      if (current is! ThreadLoaded) {
        return;
      }
      final ThreadLoaded previousState = current;
      emit(ThreadAppending());
      final Thread? thread =
          await _repository.getThread(event.threadId, event.page);
      if (thread != null) {
        // currentPage = earliest page in the main sliver window
        // endPage     = latest page in the main sliver window
        // previousPages = pages loaded upward (above the main window)
        //
        // When scrolling down, only endPage advances — currentPage must stay
        // put. Otherwise currentPage becomes the bottom page while main
        // replies still contain earlier pages, and a subsequent "load previous"
        // re-fetches those floors into previousPages → duplicate ordering
        // (e.g. p2 … p1 … p2).
        if (event.page < previousState.currentPage) {
          // Scrolling up: prepend older page above the main window.
          emit(ThreadLoaded(
              thread: previousState.thread,
              previousPages: thread.copyWith(
                  replies: thread.replies.toList()
                    ..addAll(previousState.previousPages.replies),
                  totalReplies: thread.totalReplies),
              currentPage: event.page,
              endPage: previousState.endPage));
        } else if (event.page > previousState.endPage) {
          // Scrolling down: append newer page; keep the main window start.
          emit(ThreadLoaded(
              thread: previousState.thread.copyWith(
                  replies: previousState.thread.replies.toList()
                    ..addAll(thread.replies)),
              previousPages: previousState.previousPages,
              currentPage: previousState.currentPage,
              endPage: event.page));
        } else if (event.page == previousState.endPage &&
            previousState.currentPage == previousState.endPage) {
          // Single-page window: full replace (refresh of the only loaded page).
          emit(ThreadLoaded(
              thread: previousState.thread.copyWith(replies: thread.replies),
              previousPages: previousState.previousPages,
              currentPage: previousState.currentPage,
              endPage: previousState.endPage));
        } else {
          // Page already covered by the main window [currentPage, endPage] —
          // ignore to avoid duplicate inserts / scrambled order.
          emit(previousState);
        }
      } else {
        // Keep the already-loaded thread visible on pagination failure.
        emit(previousState);
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
