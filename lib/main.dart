import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/routes.dart';
import 'package:hkgalden_flutter/redux/store.dart';
import 'package:hkgalden_flutter/ui/startup_animation.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: store,
      child: MaterialApp(
        home: StartupScreen(),
        theme: ThemeData(
          brightness: Brightness.dark,
          splashColor: Color(0xff2c3632),
          primaryColor: Color(0xff2e3533),
          scaffoldBackgroundColor: Color(0xff1b1f1e),
          appBarTheme: AppBarTheme(color: Color(0xff323d3a)),
          accentColor: Color(0xff45c17c),
          cursorColor: Color(0xff45c17c),
          textSelectionColor: Color(0xff2d8052),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            splashColor: Color(0xff4fe090),
            foregroundColor: Colors.white,
          ),
          cupertinoOverrideTheme:
              CupertinoThemeData(primaryColor: Color(0xff45c17c)),
          snackBarTheme: SnackBarThemeData(
              backgroundColor: Color(0xff323d3a),
              contentTextStyle: TextStyle(color: Colors.white)),
          pageTransitionsTheme: PageTransitionsTheme(builders: {
            TargetPlatform.android: SharedAxisPageTransitionsBuilder(
                transitionType: SharedAxisTransitionType.scaled)
          }),
        ),
        routes: routes,
      ),
    );
  }
}
