import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/channel/channel_action.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_action.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:hkgalden_flutter/redux/store.dart';
import 'package:hkgalden_flutter/secure_storage/token_secure_storage.dart';
import 'package:hkgalden_flutter/ui/home/home_page.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:hkgalden_flutter/viewmodels/startup_animation_view_model.dart';

class StartupScreen extends StatefulWidget{
  @override
  _StartupScreenState createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> with TickerProviderStateMixin {
  AnimationController _controller;
  String token;

  @override
  void initState() {
    super.initState();
    TokenSecureStorage().readToken(onFinish: (value) {
      if (value == null) {
        TokenSecureStorage().writeToken('', onFinish: (_) {
          token = '';
        });
      } else {
        token = value;
      }
    });
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this
    );
    _controller.forward();
    _controller.addStatusListener((status) { 
      if (status == AnimationStatus.completed) {
        //Hardcode default to 'bw' channel
        store.dispatch(RequestThreadAction(channelId: 'bw'));
        store.dispatch(RequestChannelAction());
        if (token != '') {
          store.dispatch(RequestSessionUserAction());
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) => Scaffold(
    body: StoreConnector<AppState, StartupAnimationViewModel>(
      onDidChange: (viewModel) {
        if (viewModel.threadIsLoading == false && viewModel.channelIsLoading == false && viewModel.sessionUserIsLoading == false) {
          Navigator.of(context).pushReplacement(FadeRoute(page: HomePage()));
        }
      },
      converter: (store) => StartupAnimationViewModel.create(store),
      builder: (BuildContext context, StartupAnimationViewModel viewModel) => Center(
        child: Container(
          width: 300,
          height: 300,
          child: StaggerAnimation(controller: _controller),
        ),
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
              child: Hero(tag: 'logo', child: SvgPicture.asset('assets/icon-hkgalden.svg')),
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