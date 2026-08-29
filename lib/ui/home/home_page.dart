import 'dart:async';

import 'package:backdrop/backdrop.dart';
import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_cubit.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_cubit.dart';
import 'package:hkgalden_flutter/bloc/thread_list/thread_list_cubit.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/ui/common/compose_page/compose_page.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/galden_fab_hero.dart';
import 'package:hkgalden_flutter/ui/common/error_page.dart';
import 'package:hkgalden_flutter/ui/home/drawer/home_drawer.dart';
import 'package:hkgalden_flutter/ui/home/skeletons/list_loading_skeleton.dart';
import 'package:hkgalden_flutter/ui/home/thread_cell.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_page.dart';

import 'package:hkgalden_flutter/utils/keys.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';
import 'package:hive/hive.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'functions/home_page_jump_to_page.dart';
part 'functions/home_page_scroll_controller_listener.dart';
part 'widgets/home_page_app_bar.dart';
part 'widgets/home_page_fab.dart';
part 'widgets/home_page_front_layer.dart';
part 'widgets/home_page_popup_menu_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  bool _loadMoreInFlight = false;
  StreamSubscription<ThreadListState>? _threadListSubscription;

  @override
  void initState() {
    _scrollController = ScrollController();
    _initListener();
    super.initState();
  }

  @override
  void dispose() {
    _threadListSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThreadListCubit threadListBloc = BlocProvider.of<ThreadListCubit>(
      context,
    );
    return PrimaryScrollController(
      controller: _scrollController,
      child: Scaffold(
        body: BackdropScaffold(
          resizeToAvoidBottomInset: false,
          appBar: _buildAppBar(),
          frontLayer: Theme(
            data: Theme.of(context)
                .copyWith(highlightColor: const Color(0xff373d3c)),
            child: RepaintBoundary(
              child: _buildFrontLayer(
                context,
                threadListBloc,
                _scrollController,
                _loadThread,
                _jumpToPage,
              ),
            ),
          ),
          frontLayerScrim: Colors.black.withAlpha(177),
          stickyFrontLayer: true,
          // Package unmounts backLayer on AnimationStatus.forward when false,
          // so the channel list would empty at the start of the collapse.
          maintainBackLayerState: true,
          backLayer: const RepaintBoundary(child: HomeDrawer()),
          backLayerBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
          floatingActionButton: _buildFab(context, threadListBloc),
        ),
      ),
    );
  }
}

void _loadThread(BuildContext context, Thread thread) {
  Navigator.of(context)
      .pushNamed('/Thread', arguments: ThreadPageArguments.fromThread(thread));
}
