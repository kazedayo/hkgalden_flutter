import 'package:bloc/bloc.dart';
import 'package:hkgalden_flutter/models/ui_state_models/thread_page_state.dart';

class ThreadPageCubit extends Cubit<ThreadPageState> {
  ThreadPageCubit()
      : super(const ThreadPageState(
            onLastPage: false, canReply: false, elevation: 0.0));

  void setOnLastPage(bool value) => emit(state.copyWith(onLastPage: value));

  void setCanReply(bool value) => emit(state.copyWith(canReply: value));

  void setElevation(double value) => emit(state.copyWith(elevation: value));
}
