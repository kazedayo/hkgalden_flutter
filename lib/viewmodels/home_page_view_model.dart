import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';

class HomePageViewModel {
  final List<Thread> threads;
  final Function onRefresh;

  HomePageViewModel({
    this.threads,
    this.onRefresh,
  });

  factory HomePageViewModel.create(Store<AppState> store) {
    return HomePageViewModel(
      threads: store.state.threadState.threads,
      onRefresh: () => store.dispatch(RequestThreadAction()),
    );
  }
}