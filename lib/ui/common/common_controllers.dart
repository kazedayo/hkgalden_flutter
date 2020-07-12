import 'package:flutter/material.dart';

AnimationController getFabAnimationController(TickerProvider vsync) {
  return AnimationController(
    duration: Duration(milliseconds: 150),
    reverseDuration: Duration(milliseconds: 75),
    value: 1,
    vsync: vsync,
  );
}
