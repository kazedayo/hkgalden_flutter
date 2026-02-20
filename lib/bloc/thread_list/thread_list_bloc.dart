import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/repository/thread_list_repository.dart';

part 'thread_list_event.dart';
part 'thread_list_state.dart';

class ThreadListBloc extends Bloc<ThreadListEvent, ThreadListState> {
  ThreadListBloc({required ThreadListRepository repository})
      : _repository = repository,
        super(ThreadListInit()) {
    on<RequestThreadListEvent>(_onRequestThreadListEvent);
  }

  final ThreadListRepository _repository;

  FutureOr<void> _onRequestThreadListEvent(
      RequestThreadListEvent event, Emitter<ThreadListState> emit) async {
    if (event.page == 1 || event.isRefresh) {
      emit(ThreadListLoading());
      final List<Thread>? threads =
          await _repository.getThreadList(event.channelId, event.page);
      if (threads != null) {
        emit(ThreadListLoaded(
            threads: threads,
            currentChannelId: event.channelId,
            currentPage: event.page));
      } else {
        emit(ThreadListError());
      }
    } else {
      final ThreadListLoaded previousState = state as ThreadListLoaded;
      emit(ThreadListAppending(
          threads: previousState.threads,
          currentChannelId: previousState.currentChannelId,
          currentPage: previousState.currentPage));
      final List<Thread>? threads =
          await _repository.getThreadList(event.channelId, event.page);
      if (threads != null) {
        emit(ThreadListLoaded(
            threads: previousState.threads.toList()..addAll(threads),
            currentChannelId: event.channelId,
            currentPage: event.page));
      } else {
        add(event);
      }
    }
  }
}
