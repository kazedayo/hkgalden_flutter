import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hkgalden_flutter/ui/home/home_page.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page.dart';
import 'package:hkgalden_flutter/utils/keys.dart';

class NestedNavigator extends StatelessWidget {
  const NestedNavigator({super.key});

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          navigatorKey.currentState!.canPop()
              ? navigatorKey.currentState!.pop()
              : SystemNavigator.pop();
        }
      },
      child: Navigator(
        key: navigatorKey,
        observers: [HeroController()],
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                  builder: (context) => const HomePage(), settings: settings);
            case '/Thread':
              return MaterialPageRoute(
                  builder: (context) => ThreadPage(), settings: settings);
            default:
              return null;
          }
        },
      ));
}
