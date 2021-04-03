import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_bloc.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread_list/thread_list_bloc.dart';
import 'package:hkgalden_flutter/nested_navigator.dart';
import 'package:hkgalden_flutter/secure_storage/token_secure_storage.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';

class StartupScreen extends StatefulWidget {
  @override
  _StartupScreenState createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late String token;

  @override
  void initState() {
    final ParagraphBuilder pb =
        ParagraphBuilder(ParagraphStyle(locale: window.locale));
    pb.addText('\ud83d\ude01'); // smiley face emoji
    pb.build().layout(const ParagraphConstraints(width: 100));
    super.initState();
    TokenSecureStorage().readToken(onFinish: (value) {
      if (value == null) {
        TokenSecureStorage().writeToken('', onFinish: (_) {
          setState(() {
            token = '';
          });
        });
      } else {
        setState(() {
          token = value as String;
        });
      }
    });
    _controller = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThreadListBloc threadListBloc =
        BlocProvider.of<ThreadListBloc>(context);
    final ChannelBloc channelBloc = BlocProvider.of<ChannelBloc>(context);
    final SessionUserBloc sessionUserBloc =
        BlocProvider.of<SessionUserBloc>(context);
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        //Hardcode default to 'bw' channel
        threadListBloc.add(const RequestThreadListEvent(
            channelId: 'bw', page: 1, isRefresh: false));
        channelBloc.add(RequestChannelsEvent());
        if (token != '') {
          sessionUserBloc.add(RequestSessionUserEvent());
        }
      }
    });
    return Scaffold(
      body: BlocListener<ThreadListBloc, ThreadListState>(
        listener: (context, state) {
          if (!state.threadListIsLoading) {
            final SizeRoute route = SizeRoute(page: NestedNavigator());
            Navigator.of(context).pushReplacement(route);
          }
        },
        child: Center(
          child: SizedBox(
            width: 300,
            height: 300,
            child: StaggerAnimation(controller: _controller),
          ),
        ),
      ),
    );
  }
}

class StaggerAnimation extends StatelessWidget {
  StaggerAnimation({Key? key, required this.controller})
      : opacity = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: controller,
            curve: const Interval(
              0.5,
              0.7,
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
            curve: const Interval(
              0.0,
              0.5,
              curve: Curves.bounceOut,
            ),
          ),
        ),
        super(key: key);

  final Animation<double> controller;
  final Animation<double> opacity;
  final Animation<double> size;

  Widget _buildAnimation(BuildContext context, Widget? child) {
    // ignore: avoid_unnecessary_containers
    return Container(
      child: Column(
        children: <Widget>[
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: SizedBox(
              width: size.value,
              height: size.value,
              child: Hero(
                  tag: 'logo',
                  child: SvgPicture.asset('assets/icon-hkgalden.svg')),
            ),
          ),
          Opacity(
            opacity: opacity.value,
            child: const ProgressSpinner(),
          ),
          const Spacer(),
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
