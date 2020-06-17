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
          primarySwatch: Colors.grey,
          accentColor: Colors.greenAccent[700],
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            foregroundColor: Colors.white,
          ),
        ),
        routes: routes,
      ),
    );
  }
}