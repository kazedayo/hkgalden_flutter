import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

part 'thread_list_event.dart';
part 'thread_list_state.dart';

class ThreadListBloc extends Bloc<ThreadListEvent, ThreadListState> {
  ThreadListBloc({required HKGaldenApi api})
      : _api = api,
        super(ThreadListInit()) {
    on<RequestThreadListEvent>(_onRequestThreadListEvent);
  }

  final HKGaldenApi _api;

  FutureOr<void> _onRequestThreadListEvent(
      RequestThreadListEvent event, Emitter<ThreadListState> emit) async {
    if (event.page == 1 || event.isRefresh) {
      final int generation = event.isRefresh && state is ThreadListLoaded
          ? (state as ThreadListLoaded).generation + 1
          : 0;
      if (!event.isRefresh || state is! ThreadListLoaded) {
        emit(ThreadListLoading());
      }
      final List<Thread>? threads =
          await _api.getThreadListQuery(event.channelId, event.page);
      if (threads != null) {
        emit(ThreadListLoaded(
            threads: threads,
            currentChannelId: event.channelId,
            currentPage: event.page,
            generation: generation));
      } else {
        emit(ThreadListError());
      }
    } else {
      if (state is ThreadListAppending) {
        return;
      }
      final ThreadListLoaded previousState = state as ThreadListLoaded;
      emit(ThreadListAppending(
          threads: previousState.threads,
          currentChannelId: previousState.currentChannelId,
          currentPage: previousState.currentPage,
          generation: previousState.generation));
      final List<Thread>? threads =
          await _api.getThreadListQuery(event.channelId, event.page);
      if (threads != null) {
        emit(ThreadListLoaded(
            threads: previousState.threads.toList()..addAll(threads),
            currentChannelId: event.channelId,
            currentPage: event.page,
            generation: previousState.generation));
      } else {
        emit(previousState);
      }
    }
  }
}
