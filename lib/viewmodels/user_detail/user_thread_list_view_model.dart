import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';

class UserThreadListViewModel {
  final bool isLoading;
  final List<Thread> userThreads;
  final int currentPage;

  UserThreadListViewModel({this.isLoading, this.userThreads, this.currentPage});

  factory UserThreadListViewModel.create(Store<AppState> store) =>
      UserThreadListViewModel(
        isLoading: store.state.userThreadListState.isLoading,
        userThreads: store.state.userThreadListState.userThreadList,
        currentPage: store.state.userThreadListState.page,
      );
}