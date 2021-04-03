import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:meta/meta.dart';

part 'user_thread_list_event.dart';
part 'user_thread_list_state.dart';

class UserThreadListBloc
    extends Bloc<UserThreadListEvent, UserThreadListState> {
  UserThreadListBloc() : super(UserThreadListState.initial());

  @override
  Stream<UserThreadListState> mapEventToState(
      UserThreadListEvent event) async* {
    if (event is RequestUserThreadListEvent) {
      yield state.copyWith(isLoading: true, page: event.page);
      final List<Thread>? userThreadList =
          await HKGaldenApi().getUserThreadList(event.userId, event.page);
      yield state.copyWith(isLoading: false, userThreadList: userThreadList);
    }
  }
}
