import 'package:flutter/material.dart';

class SizeRoute extends PageRouteBuilder {
  final Widget page;

  SizeRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 650),
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              Align(
            child: SizeTransition(
              sizeFactor: animation,
              child: child,
            ),
          ),
        );
}
