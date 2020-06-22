import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/secure_storage/token_secure_storage.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/ui/login_page.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:hkgalden_flutter/viewmodels/home_drawer_header_view_model.dart';

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
  Widget build(BuildContext context) => StoreConnector<AppState, HomeDrawerHeaderViewModel>(
    converter: (store) => HomeDrawerHeaderViewModel.create(store),
    builder: (BuildContext context, HomeDrawerHeaderViewModel viewModel) => Container(
      //height: 250,
      child: DrawerHeader(
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AvatarWidget(
              avatarImage: viewModel.sessionUserAvatar, 
              userGroup: viewModel.sessionUserGroup, 
            ),
            SizedBox(height: 7),
            Text(
              token == '' ? '未登入' : viewModel.sessionUserName,
              style: TextStyle(
                color: token == '' ? Colors.white : 
                  (viewModel.sessionUserGender == 'M' ? Color(0xff22c1fe) : Color(0xffff7aab)),
              ),
            ),
            Spacer(),
            RaisedButton(
              onPressed: () => token == '' ? 
                Navigator.push(
                  context,
                  SlideInFromBottomRoute(
                    page: LoginPage(onLoginSuccess: () => TokenSecureStorage().readToken(onFinish: (value) {
                      setState(() {
                        token = value;
                      });
                    }))
                  )
                ) : TokenSecureStorage().writeToken('', onFinish: (_) {
                  setState(() {
                    token = '';
                    viewModel.onLogout();
                  });

                }),
              child: Text(token == '' ? '登入' : '登出'),
              color: token == '' ? Colors.green[700] : Colors.redAccent[400],
            ),
          ],
        ),
        decoration: BoxDecoration(
          color: Colors.black87,
        ),
      ),
    ),
  );
}