import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';

class HomeDrawerHeaderViewModel {
  final String sessionUserName;

  HomeDrawerHeaderViewModel({
    this.sessionUserName,
  });

  factory HomeDrawerHeaderViewModel.create(Store<AppState> store) {
    return HomeDrawerHeaderViewModel(
      sessionUserName: store.state.sessionUserState.sessionUser.nickName,
    );
  }
}