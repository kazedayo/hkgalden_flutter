import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/enums/user_profile.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/secure_storage/token_secure_storage.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_detail_view.dart';
import 'package:hkgalden_flutter/ui/login_page.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:hkgalden_flutter/viewmodels/home/drawer/home_drawer_header_view_model.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';

class HomeDrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, HomeDrawerHeaderViewModel>(
        converter: (store) => HomeDrawerHeaderViewModel.create(store),
        builder: (BuildContext context, HomeDrawerHeaderViewModel viewModel) =>
            Container(
                //height: 250,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: DividerTheme(
                  data: DividerThemeData(color: Colors.transparent),
                  child: DrawerHeader(
                    margin: EdgeInsets.zero,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Spacer(flex: 2),
                        AvatarWidget(
                          avatarImage: viewModel.sessionUserAvatar,
                          userGroup: viewModel.sessionUserGroup,
                          onTap: () => viewModel.isLoggedIn
                              ? showModal<void>(
                                  context: context,
                                  builder: (context) => UserDetailView(
                                    profileType: UserProfile.sessionUser,
                                    user: viewModel.sessionUser,
                                    onLogout: () {
                                      TokenSecureStorage().writeToken('',
                                          onFinish: (_) {
                                        viewModel.onLogout();
                                      });
                                    },
                                  ),
                                )
                              : Navigator.of(context).push(
                                  SlideInFromBottomRoute(page: LoginPage())),
                        ),
                        SizedBox(height: 7),
                        Text(
                          viewModel.isLoggedIn
                              ? viewModel.sessionUserName
                              : '未登入',
                          style: TextStyle(
                              color: viewModel.isLoggedIn
                                  ? (viewModel.sessionUserGender == 'M'
                                      ? Theme.of(context)
                                          .colorScheme
                                          .brotherColor
                                      : Theme.of(context)
                                          .colorScheme
                                          .sisterColor)
                                  : Colors.white),
                        ),
                        Spacer(flex: 1),
                      ],
                    ),
                  ),
                )),
      );
}
