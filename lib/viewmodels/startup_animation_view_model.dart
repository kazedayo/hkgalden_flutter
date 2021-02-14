import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';

class StartupAnimationViewModel extends Equatable {
  final bool threadIsLoading;
  final bool channelIsLoading;
  final bool sessionUserIsLoading;

  const StartupAnimationViewModel({
    this.threadIsLoading,
    this.channelIsLoading,
    this.sessionUserIsLoading,
  });

  factory StartupAnimationViewModel.create(Store<AppState> store) {
    return StartupAnimationViewModel(
      threadIsLoading: store.state.threadListState.threadListIsLoading,
      channelIsLoading: store.state.channelState.isLoading,
      sessionUserIsLoading: store.state.sessionUserState.isLoading,
    );
  }

  @override
  List<Object> get props =>
      [threadIsLoading, channelIsLoading, sessionUserIsLoading];
}
