import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_cubit.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_cubit.dart';
import 'package:hkgalden_flutter/bloc/thread_list/thread_list_cubit.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/nested_navigator.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  StartupScreenState createState() => StartupScreenState();
}

class StartupScreenState extends State<StartupScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  bool _kickoffStarted = false;

  @override
  void initState() {
    super.initState();
    final ParagraphBuilder pb = ParagraphBuilder(
        ParagraphStyle(locale: PlatformDispatcher.instance.locale));
    pb.addText('\ud83d\ude01'); // smiley face emoji
    pb.build().layout(const ParagraphConstraints(width: 100));
    _controller = AnimationController(
        duration: const Duration(milliseconds: 2000), vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapOnce());
  }

  Future<void> _bootstrapOnce() async {
    if (_kickoffStarted || !mounted) {
      return;
    }
    _kickoffStarted = true;

    final box = Hive.box('token');
    final String? readToken = box.get('token') as String?;
    final String token;
    if (readToken == null) {
      await box.put('token', '');
      token = '';
    } else {
      token = readToken;
    }

    if (!mounted) {
      return;
    }

    await _controller.forward();
    if (!mounted) {
      return;
    }

    final threadListBloc = BlocProvider.of<ThreadListCubit>(context);
    final channelCubit = BlocProvider.of<ChannelCubit>(context);
    final sessionUserCubit = BlocProvider.of<SessionUserCubit>(context);

    threadListBloc.load(channelId: 'bw', page: 1);
    channelCubit.requestChannels();
    if (token.isNotEmpty) {
      sessionUserCubit.requestSessionUser();
      context.read<HKGaldenApi>().prewarm();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<ThreadListCubit, ThreadListState>(
        listener: (context, state) {
          if (state is ThreadListLoaded || state is ThreadListError) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 650),
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const NestedNavigator(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) => Align(
                  child: SizeTransition(sizeFactor: animation, child: child),
                ),
              ),
            );
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
  StaggerAnimation({super.key, required this.controller})
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
        );

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
          FadeTransition(
            opacity: opacity,
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
