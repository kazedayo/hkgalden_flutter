import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:hkgalden_flutter/secure_storage/token_secure_storage.dart';
import 'package:hkgalden_flutter/redux/store.dart';

class LoginPage extends StatelessWidget {
  final Function onLoginSuccess;

  LoginPage({this.onLoginSuccess});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('登入hkGalden'),
      automaticallyImplyLeading: false,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
    body: WebView(
      initialUrl: 'https://hkgalden.org/oauth/v1/authorize?client_id=${HKGaldenApi.clientId}',
      javascriptMode: JavascriptMode.unrestricted,
      navigationDelegate: (NavigationRequest request) {
        if (request.url.startsWith('http://localhost/callback')) {
          print('token: ${request.url.substring(32)}');
          _saveToken(context, request.url.substring(32));
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
    ),
  );

  Future<void> _saveToken(BuildContext context, String token) async {
    await tokenSecureStorage.write(key: 'token', value: token).then((value) {
      onLoginSuccess();
      Navigator.pop(context);
    });
  }
}