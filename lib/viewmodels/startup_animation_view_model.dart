import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';

class StartupAnimationViewModel {
  final bool threadIsLoading;
  final bool channelIsLoading;
  final bool sessionUserIsLoading;

  StartupAnimationViewModel({
    this.threadIsLoading,
    this.channelIsLoading,
    this.sessionUserIsLoading,
  });

  factory StartupAnimationViewModel.create(Store<AppState> store) {
    return StartupAnimationViewModel(
      threadIsLoading: store.state.threadState.isLoading,
      channelIsLoading: store.state.channelState.isLoading,
      sessionUserIsLoading: store.state.sessionUserState.isLoading,
    );
  }
}