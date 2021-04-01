import 'package:bloc/bloc.dart';
import 'package:hkgalden_flutter/models/ui_state_models/startup_screen_state.dart';

class StartupScreenCubit extends Cubit<StartupScreenState> {
  StartupScreenCubit() : super(const StartupScreenState(token: ''));

  void setToken(String newValue) => emit(state.copyWith(token: newValue));
}
