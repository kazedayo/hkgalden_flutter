import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/secure_storage/token_secure_storage.dart';
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
    _retrieveToken();
  }

  Future<void> _retrieveToken() async {
    await tokenSecureStorage.read(key: 'token').then((value) {
      setState(() {
        token = value;
      });
    });
  }

  Future<void> _deleteToken() async {
    await tokenSecureStorage.delete(key: 'token').then((value) {
      setState(() {
        token = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) => StoreConnector<AppState, HomeDrawerHeaderViewModel>(
    converter: (store) => HomeDrawerHeaderViewModel.create(store),
    builder: (BuildContext context, HomeDrawerHeaderViewModel viewModel) => Container(
      height: 250,
      child: DrawerHeader(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              child: Icon(Icons.account_circle, size: 50,),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xff7435a0),Color(0xff4a72d3)],
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              token == null ? '未登入' : viewModel.sessionUserName,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            RaisedButton(
              onPressed: () => token == null ? Navigator.push(context, SlideInFromBottomRoute(page: LoginPage(onLoginSuccess: () => _retrieveToken(),))) : _deleteToken(),
              child: Text(token == null ? '登入' : '登出'),
              color: token == null ? Colors.green[700] : Colors.redAccent[400],
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