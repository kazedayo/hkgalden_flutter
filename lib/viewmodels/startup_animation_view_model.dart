import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';

class StartupAnimationViewModel {
  final bool threadIsLoading;

  StartupAnimationViewModel({
    this.threadIsLoading,
  });

  factory StartupAnimationViewModel.create(Store<AppState> store) {
    return StartupAnimationViewModel(
      threadIsLoading: store.state.threadState.isLoading,
    );
  }
}