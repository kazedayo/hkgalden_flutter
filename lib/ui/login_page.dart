import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LoginPage extends StatelessWidget {
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
          Navigator.pop(context);
          print('token: ${request.url.substring(32)}');
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
    ),
  );
}