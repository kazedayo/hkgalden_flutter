import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/ui/home/home_page.dart';
import 'package:hkgalden_flutter/ui/startup_animation.dart';

String appTitle = 'hkGalden UI Mockup';

Map<String, WidgetBuilder> routes = {
  '/Home': (BuildContext context) => new HomePage(title: appTitle),
  '/Splash': (BuildContext context) => new StartupScreen(),
};