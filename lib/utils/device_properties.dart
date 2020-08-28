import 'package:flutter/material.dart';

double displayHeight(BuildContext context) =>
    MediaQuery.of(context).size.height;

double displayWidth(BuildContext context) =>
    MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio;

double displayLogicalWidth(BuildContext context) =>
    MediaQuery.of(context).size.width;
