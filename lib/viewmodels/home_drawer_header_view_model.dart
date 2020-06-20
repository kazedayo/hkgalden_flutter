import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hkgalden_flutter/models/user_group.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_action.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:redux/redux.dart';

class HomeDrawerHeaderViewModel {
  final String sessionUserName;
  final Widget sessionUserAvatar;
  final List<UserGroup> sessionUserGroup;
  final Function onLogout;

  HomeDrawerHeaderViewModel({
    this.sessionUserName,
    this.sessionUserAvatar,
    this.sessionUserGroup,
    this.onLogout,
  });

  factory HomeDrawerHeaderViewModel.create(Store<AppState> store) {
    return HomeDrawerHeaderViewModel(
      sessionUserName: store.state.sessionUserState.sessionUser.nickName,
      sessionUserAvatar: store.state.sessionUserState.sessionUser.avatar == '' ? 
        SvgPicture.asset('assets/icon-hkgalden.svg', width: 30, height: 30) : 
        CachedNetworkImage(imageUrl: store.state.sessionUserState.sessionUser.avatar, width: 30,height: 30),
      sessionUserGroup: store.state.sessionUserState.sessionUser.userGroup,
      onLogout: () {
        store.dispatch(RemoveSessionUserAction());
        store.dispatch(RequestThreadListAction(
          channelId: store.state.channelState.selectedChannelId,
          page: 1, 
          isRefresh: false
        ));
      }
    );
  }
}