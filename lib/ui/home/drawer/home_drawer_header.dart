import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/secure_storage/token_secure_storage.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_detail_view.dart';
import 'package:hkgalden_flutter/ui/login_page.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:hkgalden_flutter/viewmodels/home/drawer/home_drawer_header_view_model.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';

class HomeDrawerHeader extends StatefulWidget {
  @override
  _HomeDrawerHeaderState createState() => _HomeDrawerHeaderState();
}

class _HomeDrawerHeaderState extends State<HomeDrawerHeader> {
  String token;

  @override
  void initState() {
    //token = null;
    TokenSecureStorage().readToken(onFinish: (value) {
      setState(() {
        token = value;
      });
    });
    super.initState();
  }

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
                        Spacer(),
                        AvatarWidget(
                          avatarImage: viewModel.sessionUserAvatar,
                          userGroup: viewModel.sessionUserGroup,
                          onTap: () => token == ''
                              ? Navigator.push(
                                  context,
                                  SlideInFromBottomRoute(
                                      page: LoginPage(
                                          onLoginSuccess: () =>
                                              TokenSecureStorage().readToken(
                                                  onFinish: (value) {
                                                setState(() {
                                                  token = value;
                                                });
                                              }))))
                              : showModal<void>(
                                  context: context,
                                  builder: (context) => UserDetailView(
                                    onLogout: () {
                                      TokenSecureStorage().writeToken('',
                                          onFinish: (_) {
                                        setState(() {
                                          token = '';
                                          viewModel.onLogout();
                                        });
                                      });
                                    },
                                  ),
                                ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          token == '' ? '未登入' : viewModel.sessionUserName,
                          style: TextStyle(
                            color: token == ''
                                ? Colors.white
                                : (viewModel.sessionUserGender == 'M'
                                    ? Theme.of(context).colorScheme.brotherColor
                                    : Theme.of(context)
                                        .colorScheme
                                        .sisterColor),
                          ),
                        ),
                        Spacer(),
                      ],
                    ),
                  ),
                )),
      );
}
