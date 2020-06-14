import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';

class HomePageViewModel {
  final List<Thread> threads;

  HomePageViewModel({
    this.threads
  });

  factory HomePageViewModel.create(Store<AppState> store) {
    return HomePageViewModel(
      threads: store.state.threadState.threads,
    );
  }
}