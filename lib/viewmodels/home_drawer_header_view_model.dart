import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/user_group.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';

class HomeDrawerHeaderViewModel {
  final String sessionUserName;
  final Image sessionUserAvatar;
  final List<UserGroup> sessionUserGroup;

  HomeDrawerHeaderViewModel({
    this.sessionUserName,
    this.sessionUserAvatar,
    this.sessionUserGroup,
  });

  factory HomeDrawerHeaderViewModel.create(Store<AppState> store) {
    return HomeDrawerHeaderViewModel(
      sessionUserName: store.state.sessionUserState.sessionUser.nickName,
      sessionUserAvatar: store.state.sessionUserState.sessionUser.avatar == '' ? Image.asset('assets/default-icon.png') : Image.network(store.state.sessionUserState.sessionUser.avatar),
      sessionUserGroup: store.state.sessionUserState.sessionUser.userGroup,
    );
  }
}