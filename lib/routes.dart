import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/home/home_page.dart';
import 'package:hkgalden_flutter/ui/startup_animation.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page.dart';

Map<String, WidgetBuilder> routes = {
  '/Home': (BuildContext context) => new HomePage(),
  '/Splash': (BuildContext context) => new StartupScreen(),
  //'/Thread': (BuildContext context) => new ThreadPage(),
};
