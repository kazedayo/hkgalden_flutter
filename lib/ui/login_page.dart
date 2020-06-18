import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_action.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:hkgalden_flutter/secure_storage/token_secure_storage.dart';
import 'package:hkgalden_flutter/redux/store.dart';

class LoginPage extends StatelessWidget {
  final Function onLoginSuccess;
  WebViewController _controller;

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
      onWebViewCreated: (controller) => this._controller = controller,
      navigationDelegate: (NavigationRequest request) {
        if (request.url.startsWith('http://localhost/callback')) {
          TokenSecureStorage().writeToken(request.url.substring(32), onFinish: (_) {
            onLoginSuccess();
            store.dispatch(RequestSessionUserAction());
            store.dispatch(RequestThreadListAction(channelId: store.state.channelState.selectedChannelId, isRefresh: false));
            Navigator.pop(context);
          });
          return NavigationDecision.prevent;
        }
        return NavigationDecision.navigate;
      },
      onPageFinished: (url) async {
        try {
          var javascript = '''
            window.alert = function (e){
              Alert.postMessage(e);
            }
          ''';
          await _controller?.evaluateJavascript(javascript);
        } catch (_) {}
      },
      javascriptChannels: <JavascriptChannel>[_alertJavascriptChannel(context)].toSet(),
    ),
  );
  
  JavascriptChannel _alertJavascriptChannel(BuildContext context) {
    return JavascriptChannel(name: 'Alert', onMessageReceived: (JavascriptMessage message) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            // return object of type Dialog
            return AlertDialog(
              title: new Text("登入失敗!"),
              content: new Text(message.message),
              actions: <Widget>[
                // usually buttons at the bottom of the dialog
                new FlatButton(
                  child: new Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } 
    );
  }
}