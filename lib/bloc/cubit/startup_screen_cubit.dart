import 'package:bloc/bloc.dart';
import 'package:hkgalden_flutter/models/ui_state_models/startup_screen_state.dart';
import 'package:hkgalden_flutter/secure_storage/token_secure_storage.dart';

class StartupScreenCubit extends Cubit<StartupScreenState> {
  static String get userToken {
    TokenSecureStorage().readToken(onFinish: (value) {
      if (value == null) {
        TokenSecureStorage().writeToken('', onFinish: (_) {
          return '';
        });
      } else {
        return value as String;
      }
    });
    return '';
  }

  StartupScreenCubit() : super(StartupScreenState(token: userToken));

  void setToken(String newValue) => emit(state.copyWith(token: newValue));
}
