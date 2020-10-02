import 'package:cached_network_image/cached_network_image.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/models/user_group.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';

class SessionUserPageViewModel extends Equatable {
  final User sessionUser;
  final String sessionUserName;
  final Widget sessionUserAvatar;
  final String sessionUserGender;
  final List<UserGroup> sessionUserGroup;

  SessionUserPageViewModel({
    this.sessionUser,
    this.sessionUserName,
    this.sessionUserAvatar,
    this.sessionUserGender,
    this.sessionUserGroup,
  });

  factory SessionUserPageViewModel.create(Store<AppState> store) {
    return SessionUserPageViewModel(
      sessionUser: store.state.sessionUserState.sessionUser,
      sessionUserName: store.state.sessionUserState.sessionUser.nickName,
      sessionUserAvatar: store.state.sessionUserState.sessionUser.avatar == ''
          ? SvgPicture.asset('assets/icon-hkgalden.svg',
              width: 30, height: 30, color: Colors.grey)
          : CachedNetworkImage(
              width: 30,
              height: 30,
              imageUrl: store.state.sessionUserState.sessionUser.avatar,
              placeholder: (context, url) => SizedBox.fromSize(
                size: Size.square(30),
              ),
            ),
      sessionUserGender: store.state.sessionUserState.sessionUser.gender,
      sessionUserGroup: store.state.sessionUserState.sessionUser.userGroup,
    );
  }

  List<Object> get props => [
        sessionUser,
        sessionUserName,
        sessionUserAvatar,
        sessionUserGender,
        sessionUserGroup
      ];
}
