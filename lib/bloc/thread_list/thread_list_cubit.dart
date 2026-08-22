import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

part 'thread_list_state.dart';

class ThreadListCubit extends Cubit<ThreadListState> {
  ThreadListCubit({required HKGaldenApi api})
      : _api = api,
        super(ThreadListLoading());

  final HKGaldenApi _api;

  Future<void> load({
    required String channelId,
    required int page,
    bool isRefresh = false,
  }) async {
    if (page == 1 || isRefresh) {
      if (!isRefresh || state is! ThreadListLoaded) {
        emit(ThreadListLoading());
      }
      final List<Thread>? threads =
          await _api.getThreadListQuery(channelId, page);
      if (threads != null) {
        emit(ThreadListLoaded(
            threads: threads,
            currentChannelId: channelId,
            currentPage: page));
      } else {
        emit(ThreadListError());
      }
    } else {
      final current = state;
      if (current is! ThreadListLoaded || current is ThreadListAppending) {
        return;
      }
      final ThreadListLoaded previousState = current;
      emit(ThreadListAppending(
          threads: previousState.threads,
          currentChannelId: previousState.currentChannelId,
          currentPage: previousState.currentPage));
      final List<Thread>? threads =
          await _api.getThreadListQuery(channelId, page);
      if (threads != null) {
        emit(ThreadListLoaded(
            threads: previousState.threads.toList()..addAll(threads),
            currentChannelId: channelId,
            currentPage: page));
      } else {
        emit(previousState);
      }
    }
  }
}
