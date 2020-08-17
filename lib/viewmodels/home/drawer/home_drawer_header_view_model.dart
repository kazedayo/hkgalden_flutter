import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_networkimage/provider.dart';
import 'package:flutter_advanced_networkimage/transition.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/models/user_group.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_action.dart';
import 'package:hkgalden_flutter/redux/thread_list/thread_list_action.dart';
import 'package:redux/redux.dart';

class HomeDrawerHeaderViewModel extends Equatable {
  final bool isLoggedIn;
  final User sessionUser;
  final String sessionUserName;
  final Widget sessionUserAvatar;
  final String sessionUserGender;
  final List<UserGroup> sessionUserGroup;
  final Function onLogout;

  HomeDrawerHeaderViewModel({
    this.isLoggedIn,
    this.sessionUser,
    this.sessionUserName,
    this.sessionUserAvatar,
    this.sessionUserGender,
    this.sessionUserGroup,
    this.onLogout,
  });

  factory HomeDrawerHeaderViewModel.create(Store<AppState> store) {
    return HomeDrawerHeaderViewModel(
        isLoggedIn: store.state.sessionUserState.isLoggedIn,
        sessionUser: store.state.sessionUserState.sessionUser,
        sessionUserName: store.state.sessionUserState.sessionUser.nickName,
        sessionUserAvatar: store.state.sessionUserState.sessionUser.avatar == ''
            ? SvgPicture.asset('assets/icon-hkgalden.svg',
                width: 30, height: 30, color: Colors.grey)
            : TransitionToImage(
                loadingWidget: SizedBox.fromSize(
                  size: Size.square(30),
                ),
                image: AdvancedNetworkImage(
                    store.state.sessionUserState.sessionUser.avatar),
                width: 30,
                height: 30,
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

  List<Object> get props => [
        isLoggedIn,
        sessionUser,
        sessionUserName,
        sessionUserAvatar,
        sessionUserGender,
        sessionUserGroup
      ];
}
