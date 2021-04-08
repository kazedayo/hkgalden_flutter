import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

part 'user_thread_list_event.dart';
part 'user_thread_list_state.dart';

class UserThreadListBloc
    extends Bloc<UserThreadListEvent, UserThreadListState> {
  UserThreadListBloc() : super(UserThreadListLoading());

  @override
  Stream<UserThreadListState> mapEventToState(
      UserThreadListEvent event) async* {
    if (event is RequestUserThreadListEvent) {
      final List<Thread>? userThreadList =
          await HKGaldenApi().getUserThreadList(event.userId, event.page);
      if (userThreadList != null) {
        yield UserThreadListLoaded(
            page: event.page, userThreadList: userThreadList);
      }
    }
  }
}
