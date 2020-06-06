import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

class StartupScreen extends StatefulWidget{
  @override
  _StartupScreenState createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> with TickerProviderStateMixin {
  AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this
    );
    _startTime();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  //hardcode animation duration
  _startTime() async {
    var _duration = Duration(milliseconds: 3000);
    return new Timer(_duration, navigationPage);
  }

  void navigationPage() {
    Navigator.of(context).pushReplacementNamed('/Home');
  }
 
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Container(
        width: 300,
        height: 300,
        child: StaggerAnimation(controller: _controller),
      ),
    ),
  );
}

class StaggerAnimation extends StatelessWidget {
  StaggerAnimation({ Key key, this.controller }) :

    opacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          0.5, 0.7,
          curve: Curves.ease,
        ),
      ),
    ),

    size = Tween<double>(
      begin: 0.0,
      end: 100.0,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          0.0, 0.5,
          curve: Curves.bounceOut,
        ),
      ),
    ),

    super(key: key);

  final Animation<double> controller;
  final Animation<double> opacity;
  final Animation<double> size;

  Widget _buildAnimation(BuildContext context, Widget child) {
    return Container(
      child: Column(
        children: <Widget>[
          Spacer(),
          Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: SizedBox(
              width: size.value,
              height: size.value,
              child: SvgPicture.asset('assets/icon-hkgalden.svg'),
            ),
          ),
          Opacity(
            opacity: opacity.value,
            child: SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2.0,valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]),),
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      builder: _buildAnimation,
      animation: controller,
    );
  }
}