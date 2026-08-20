import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

part 'user_thread_list_state.dart';

class UserThreadListCubit extends Cubit<UserThreadListState> {
  UserThreadListCubit({required HKGaldenApi api})
      : _api = api,
        super(UserThreadListLoading());

  final HKGaldenApi _api;

  Future<void> load({required String userId, required int page}) async {
    emit(UserThreadListLoading());
    final List<Thread>? userThreadList =
        await _api.getUserThreadList(userId, page);
    if (userThreadList != null) {
      emit(UserThreadListLoaded(page: page, userThreadList: userThreadList));
    } else {
      emit(UserThreadListError());
    }
  }
}
