import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

part 'user_thread_list_event.dart';
part 'user_thread_list_state.dart';

class UserThreadListBloc
    extends Bloc<UserThreadListEvent, UserThreadListState> {
  UserThreadListBloc({required HKGaldenApi api})
      : _api = api,
        super(UserThreadListLoading()) {
    on<RequestUserThreadListEvent>(_onRequestUserThreadListEvent);
  }

  final HKGaldenApi _api;

  FutureOr<void> _onRequestUserThreadListEvent(RequestUserThreadListEvent event,
      Emitter<UserThreadListState> emit) async {
    emit(UserThreadListLoading());
    final List<Thread>? userThreadList =
        await _api.getUserThreadList(event.userId, event.page);
    if (userThreadList != null) {
      emit(UserThreadListLoaded(
          page: event.page, userThreadList: userThreadList));
    } else {
      emit(UserThreadListError());
    }
  }
}
