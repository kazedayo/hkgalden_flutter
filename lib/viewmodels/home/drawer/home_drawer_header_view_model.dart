import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/models/user_group.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_action.dart';
import 'package:hkgalden_flutter/redux/thread_list/thread_list_action.dart';
import 'package:redux/redux.dart';

class HomeDrawerHeaderViewModel {
  final User sessionUser;
  final String sessionUserName;
  final Widget sessionUserAvatar;
  final String sessionUserGender;
  final List<UserGroup> sessionUserGroup;
  final Function onLogout;

  HomeDrawerHeaderViewModel({
    this.sessionUser,
    this.sessionUserName,
    this.sessionUserAvatar,
    this.sessionUserGender,
    this.sessionUserGroup,
    this.onLogout,
  });

  factory HomeDrawerHeaderViewModel.create(Store<AppState> store) {
    return HomeDrawerHeaderViewModel(
        sessionUser: store.state.sessionUserState.sessionUser,
        sessionUserName: store.state.sessionUserState.sessionUser.nickName,
        sessionUserAvatar: store.state.sessionUserState.sessionUser.avatar == ''
            ? SvgPicture.asset('assets/icon-hkgalden.svg',
                width: 30, height: 30, color: Colors.grey)
            : CachedNetworkImage(
                imageUrl: store.state.sessionUserState.sessionUser.avatar,
                width: 30,
                height: 30,
                fadeInDuration: Duration(milliseconds: 250),
                fadeOutDuration: Duration(milliseconds: 250),
              ),
        sessionUserGender: store.state.sessionUserState.sessionUser.gender,
        sessionUserGroup: store.state.sessionUserState.sessionUser.userGroup,
        onLogout: () {
          store.dispatch(RemoveSessionUserAction());
          store.dispatch(RequestThreadListAction(
              channelId: store.state.channelState.selectedChannelId,
              page: 1,
              isRefresh: false));
        });
  }
}
