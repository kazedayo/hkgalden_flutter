import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_bloc.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread_list/thread_list_bloc.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:hkgalden_flutter/utils/token_store.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late WebViewController _controller;

  @override
  Widget build(BuildContext context) {
    final SessionUserBloc sessionUserBloc =
        BlocProvider.of<SessionUserBloc>(context);
    final ThreadListBloc threadListBloc =
        BlocProvider.of<ThreadListBloc>(context);
    final ChannelBloc channelBloc = BlocProvider.of<ChannelBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '登入hkGalden',
          style: Theme.of(context)
              .textTheme
              .subtitle1!
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
        navigationDelegate: (NavigationRequest request) async {
          if (request.url.startsWith('http://localhost/callback')) {
            await TokenStore().writeToken(request.url.substring(32));
            sessionUserBloc.add(RequestSessionUserEvent());
            threadListBloc.add(RequestThreadListEvent(
                channelId:
                    (channelBloc.state as ChannelLoaded).selectedChannelId,
                page: 1,
                isRefresh: false));
            Navigator.pop(context);
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
            await _controller.evaluateJavascript(javascript);
          } catch (_) {}
        },
        javascriptChannels: <JavascriptChannel>{
          _alertJavascriptChannel(context)
        },
      ),
    );
  }

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
