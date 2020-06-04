import 'package:flutter/material.dart';
import 'ui_mock.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  final appTitle = 'UI Mockup';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      home: MyHomePage(title: appTitle),
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.grey,
        accentColor: Colors.greenAccent[700],
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}