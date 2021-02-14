import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hkgalden_flutter/ui/home/home_page.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page.dart';
import 'package:hkgalden_flutter/utils/keys.dart';

class NestedNavigator extends StatelessWidget {
  @override
  Widget build(BuildContext context) => WillPopScope(
      onWillPop: () async {
        navigatorKey.currentState.canPop()
            ? navigatorKey.currentState.pop()
            : SystemNavigator.pop();
        //navigatorKey.currentState.pop();
        return false;
      },
      child: Navigator(
        key: navigatorKey,
        observers: [HeroController()],
        onGenerateRoute: (settings) {
          WidgetBuilder builder;
          switch (settings.name) {
            case '/':
              builder = (context) => const HomePage();
              break;
            case '/Thread':
              builder = (context) => ThreadPage();
              break;
            default:
              break;
          }
          return MaterialPageRoute(builder: builder, settings: settings);
        },
      ));
}
