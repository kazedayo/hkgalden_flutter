import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class StartupScreen extends StatefulWidget{
  @override
  _StartupScreenState createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> with TickerProviderStateMixin {
  AnimationController _controller;
  bool _isPlaying;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this
    );
    _isPlaying = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _playAnimation() {
    if (!_isPlaying) {
      setState(() {
        _isPlaying = true;
      });
    } else {
      setState(() {
        _controller.dispose();
        _controller = AnimationController(
          duration: const Duration(milliseconds: 2000),
          vsync: this
        );
      });
    }
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 300,
            height: 300,
            child: StaggerAnimation(controller: _controller),
          ),
          RaisedButton(
            onPressed: () => _playAnimation(),
            child: _isPlaying ? Text('Replay Animation') : Text('Play Animation'),
          ),
          RaisedButton(onPressed: () => Navigator.pop(context), child: Text('Go Back'),)
        ],
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