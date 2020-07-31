import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/secure_storage/token_secure_storage.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/ui/login_page.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:hkgalden_flutter/viewmodels/home/drawer/home_drawer_header_view_model.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';

class HomeDrawerHeader extends StatelessWidget {
  final Function onAvatarTap;

  const HomeDrawerHeader({Key key, this.onAvatarTap}) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, HomeDrawerHeaderViewModel>(
        distinct: true,
        converter: (store) => HomeDrawerHeaderViewModel.create(store),
        builder: (BuildContext context, HomeDrawerHeaderViewModel viewModel) =>
            Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: DividerTheme(
                  data: DividerThemeData(color: Colors.transparent),
                  child: Container(
                    margin: EdgeInsets.only(bottom: 20, top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        AvatarWidget(
                          avatarImage: viewModel.sessionUserAvatar,
                          userGroup: viewModel.sessionUserGroup,
                          onTap: () => viewModel.isLoggedIn
                              ? onAvatarTap()
                              : Navigator.of(context).push(
                                  SlideInFromBottomRoute(page: LoginPage())),
                        ),
                        SizedBox(width: 10),
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
                        Spacer(),
                        Visibility(
                          visible: viewModel.isLoggedIn,
                          child: Row(
                            children: <Widget>[
                              IconButton(
                                  icon: Icon(Icons.settings), onPressed: null),
                              IconButton(
                                icon: Icon(Icons.exit_to_app),
                                onPressed: () => TokenSecureStorage()
                                    .writeToken('', onFinish: (_) {
                                  viewModel.onLogout();
                                }),
                                color: Colors.redAccent[400],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                )),
      );
}
