import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

part 'thread_state.dart';

class ThreadCubit extends Cubit<ThreadState> {
  ThreadCubit({required HKGaldenApi api})
      : _api = api,
        super(ThreadLoading());

  final HKGaldenApi _api;

  Future<void> request({
    required int threadId,
    required int page,
    required bool isInitialLoad,
  }) async {
    if (isInitialLoad) {
      emit(ThreadLoading());
      final Thread? thread = await _api.getThreadQuery(threadId, page);
      if (thread != null) {
        emit(ThreadLoaded(
            thread: thread,
            previousReplies: const [],
            currentPage: page,
            endPage: page));
      } else {
        emit(ThreadError());
      }
    } else {
      final current = state;
      if (current is! ThreadLoaded) {
        return;
      }
      final ThreadLoaded previousState = current;
      emit(ThreadAppending());
      final Thread? thread = await _api.getThreadQuery(threadId, page);
      if (thread != null) {
        if (page < previousState.currentPage) {
          emit(ThreadLoaded(
              thread: previousState.thread,
              previousReplies: [
                ...thread.replies,
                ...previousState.previousReplies,
              ],
              currentPage: page,
              endPage: previousState.endPage));
        } else if (page > previousState.endPage) {
          emit(ThreadLoaded(
              thread: previousState.thread.copyWith(
                  replies: previousState.thread.replies.toList()
                    ..addAll(thread.replies)),
              previousReplies: previousState.previousReplies,
              currentPage: previousState.currentPage,
              endPage: page));
        } else if (page == previousState.endPage &&
            previousState.currentPage == previousState.endPage) {
          emit(ThreadLoaded(
              thread: previousState.thread.copyWith(replies: thread.replies),
              previousReplies: previousState.previousReplies,
              currentPage: previousState.currentPage,
              endPage: previousState.endPage));
        } else {
          emit(previousState);
        }
      } else {
        emit(previousState);
      }
    }
  }

  void appendReply(Reply reply) {
    if (state is ThreadLoaded) {
      final ThreadLoaded previousState = state as ThreadLoaded;
      emit(ThreadAppending());
      final List<Reply> replies = previousState.thread.replies.toList();
      replies.add(reply);
      emit(ThreadLoaded(
          thread: previousState.thread.copyWith(replies: replies),
          previousReplies: previousState.previousReplies,
          currentPage: previousState.currentPage,
          endPage: previousState.endPage));
    }
  }
}
