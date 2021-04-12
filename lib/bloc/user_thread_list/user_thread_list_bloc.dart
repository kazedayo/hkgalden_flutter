import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/repository/user_thread_list_repository.dart';

part 'user_thread_list_event.dart';
part 'user_thread_list_state.dart';

class UserThreadListBloc
    extends Bloc<UserThreadListEvent, UserThreadListState> {
  UserThreadListBloc({required UserThreadListRepository repository})
      : _repository = repository,
        super(UserThreadListLoading());

  final UserThreadListRepository _repository;

  @override
  Stream<UserThreadListState> mapEventToState(
      UserThreadListEvent event) async* {
    if (event is RequestUserThreadListEvent) {
      final List<Thread>? userThreadList =
          await _repository.getUserThreadList(event.userId, event.page);
      if (userThreadList != null) {
        yield UserThreadListLoaded(
            page: event.page, userThreadList: userThreadList);
      }
    }
  }
}
