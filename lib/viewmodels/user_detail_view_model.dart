import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hkgalden_flutter/models/user_group.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';

class UserDetailViewModel {
  final Widget userAvatar;
  final String userName;
  final String userGender;
  final List<UserGroup> userGroup;

  UserDetailViewModel({
    this.userAvatar,
    this.userName,
    this.userGender,
    this.userGroup,
  });

  factory UserDetailViewModel.create(Store<AppState> store) {
    return UserDetailViewModel(
        userAvatar: store.state.sessionUserState.sessionUser.avatar == ''
            ? SvgPicture.asset('assets/icon-hkgalden.svg',
                width: 30, height: 30)
            : CachedNetworkImage(
                imageUrl: store.state.sessionUserState.sessionUser.avatar,
                width: 30,
                height: 30,
                fadeInDuration: Duration(milliseconds: 250),
                fadeOutDuration: Duration(milliseconds: 250),
              ),
        userName: store.state.sessionUserState.sessionUser.nickName,
        userGender: store.state.sessionUserState.sessionUser.gender,
        userGroup: store.state.sessionUserState.sessionUser.userGroup);
  }
}
