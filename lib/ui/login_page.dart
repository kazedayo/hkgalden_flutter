import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_action.dart';
import 'package:hkgalden_flutter/redux/thread_list/thread_list_action.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:hkgalden_flutter/secure_storage/token_secure_storage.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  WebViewController _controller;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(
            '登入hkGalden',
            style: Theme.of(context)
                .textTheme
                .subtitle1
                .copyWith(fontWeight: FontWeight.bold),
          ),
          automaticallyImplyLeading: false,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: WebView(
          initialUrl:
              'https://hkgalden.org/oauth/v1/authorize?client_id=${HKGaldenApi.clientId}',
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (controller) => _controller = controller,
          navigationDelegate: (NavigationRequest request) {
            if (request.url.startsWith('http://localhost/callback')) {
              TokenSecureStorage().writeToken(request.url.substring(32),
                  onFinish: (_) {
                StoreProvider.of<AppState>(context)
                    .dispatch(RequestSessionUserAction());
                StoreProvider.of<AppState>(context).dispatch(
                    RequestThreadListAction(
                        channelId: StoreProvider.of<AppState>(context)
                            .state
                            .channelState
                            .selectedChannelId,
                        page: 1,
                        isRefresh: false));
                Navigator.pop(context);
              });
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (url) async {
            try {
              const javascript = '''
            window.alert = function (e){
              Alert.postMessage(e);
            }
          ''';
              await _controller?.evaluateJavascript(javascript);
            } catch (_) {}
          },
          javascriptChannels: <JavascriptChannel>{
            _alertJavascriptChannel(context)
          },
        ),
      );

  JavascriptChannel _alertJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Alert',
        onMessageReceived: (JavascriptMessage message) {
          showCustomDialog(
            context: context,
            builder: (BuildContext context) {
              // return object of type Dialog
              return CustomAlertDialog(
                  title: '登入失敗!', content: message.message);
            },
          );
        });
  }
}
