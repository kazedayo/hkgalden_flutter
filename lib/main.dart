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
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            foregroundColor: Colors.white,
          ),
        ),
        routes: routes,
      ),
    );
  }
}