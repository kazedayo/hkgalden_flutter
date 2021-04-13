import 'dart:ui';

import 'package:backdrop/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_bloc.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread_list/thread_list_bloc.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/utils/token_store.dart';
import 'package:hkgalden_flutter/ui/common/compose_page.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/home/drawer/home_drawer.dart';
import 'package:hkgalden_flutter/ui/home/skeletons/list_loading_skeleton.dart';
import 'package:hkgalden_flutter/ui/home/skeletons/list_loading_skeleton_cell.dart';
import 'package:hkgalden_flutter/ui/home/thread_cell.dart';
import 'package:hkgalden_flutter/ui/login_page.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:hkgalden_flutter/ui/user_detail/block_list_page.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_page.dart';
import 'package:hkgalden_flutter/utils/device_properties.dart';
import 'package:hkgalden_flutter/utils/keys.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:package_info/package_info.dart';

part 'widgets/home_page_app_bar.dart';
part 'widgets/home_page_popup_menu_button.dart';
part 'widgets/home_page_leading_button.dart';
part 'widgets/home_page_fab.dart';
part 'widgets/home_page_front_layer.dart';

class HomePage extends StatefulWidget {
  final String? title;

  const HomePage({Key? key, this.title}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _backgroundBlurAnimationController;
  late bool _fabIsHidden;
  late bool _menuIsShowing;

  @override
  void initState() {
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        BlocProvider.of<ThreadListBloc>(context).add(RequestThreadListEvent(
            channelId: (BlocProvider.of<ThreadListBloc>(context).state
                    as ThreadListLoaded)
                .currentChannelId,
            page: (BlocProvider.of<ThreadListBloc>(context).state
                        as ThreadListLoaded)
                    .currentPage +
                1,
            isRefresh: false));
      }
      if ((_scrollController.position.userScrollDirection ==
                  ScrollDirection.forward ||
              _scrollController.position.pixels == 0.0) &&
          _fabIsHidden) {
        setState(() {
          _fabIsHidden = false;
        });
      } else if (_scrollController.position.userScrollDirection ==
              ScrollDirection.reverse &&
          !_fabIsHidden) {
        setState(() {
          _fabIsHidden = true;
        });
      }
    });
    _backgroundBlurAnimationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150),
        reverseDuration: const Duration(milliseconds: 200),
        value: 0.0,
        upperBound: 0.5)
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          setState(() {
            _menuIsShowing = false;
          });
        }
      });
    _fabIsHidden = false;
    _menuIsShowing = false;
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _backgroundBlurAnimationController.dispose();
    super.dispose();
  }

  // @override
  // void didChangeDependencies() {
  //   context.dependOnInheritedWidgetOfExactType();
  //   super.didChangeDependencies();
  // }

  @override
  Widget build(BuildContext context) {
    final ThreadListBloc threadListBloc =
        BlocProvider.of<ThreadListBloc>(context);
    final SessionUserBloc sessionUserBloc =
        BlocProvider.of<SessionUserBloc>(context);
    final ChannelBloc channelBloc = BlocProvider.of<ChannelBloc>(context);
    return BlocBuilder<ThreadListBloc, ThreadListState>(
      buildWhen: (_, state) => state is! ThreadListAppending,
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              BackdropScaffold(
                resizeToAvoidBottomInset: false,
                appBar: _buildAppBar(),
                frontLayer: _buildFrontLayer(
                    context,
                    threadListBloc,
                    channelBloc,
                    state,
                    sessionUserBloc,
                    _scrollController,
                    _loadThread,
                    _jumpToPage),
                frontLayerScrim: Colors.black.withAlpha(177),
                stickyFrontLayer: true,
                backLayer: HomeDrawer(),
                backLayerBackgroundColor:
                    Theme.of(context).scaffoldBackgroundColor,
                floatingActionButton:
                    _fabIsHidden ? null : _buildFab(context, threadListBloc),
              ),
              Visibility(
                visible: _menuIsShowing,
                child: AnimatedBuilder(
                  animation: _backgroundBlurAnimationController,
                  builder: (context, child) => BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      color: Colors.black.withOpacity(
                          _backgroundBlurAnimationController.value),
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _loadThread(Thread thread) {
    Navigator.of(context).pushNamed('/Thread',
        arguments: ThreadPageArguments(
            threadId: thread.threadId,
            title: thread.title,
            page: 1,
            locked: thread.status == 'locked'));
  }

  void _jumpToPage(Thread thread) {
    HapticFeedback.mediumImpact();
    showMaterialModalBottomSheet(
      useRootNavigator: true,
      duration: const Duration(milliseconds: 200),
      animationCurve: Curves.easeOut,
      enableDrag: false,
      barrierColor: Colors.black.withOpacity(0.5),
      context: context,
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(highlightColor: Colors.grey[800]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Text(
                thread.title,
                style: Theme.of(context)
                    .textTheme
                    .headline6!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ConstrainedBox(
              constraints:
                  BoxConstraints(maxHeight: displayHeight(context) / 2),
              child: ListView.builder(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom),
                shrinkWrap: true,
                itemCount: (thread.replies.last.floor.toDouble() / 50.0).ceil(),
                itemBuilder: (context, index) => Card(
                  color: Colors.transparent,
                  elevation: 0,
                  clipBehavior: Clip.hardEdge,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: SimpleDialogOption(
                    padding: const EdgeInsets.all(16.0),
                    onPressed: () {
                      Navigator.of(context).pop();
                      navigatorKey.currentState!.pushNamed('/Thread',
                          arguments: ThreadPageArguments(
                              threadId: thread.threadId,
                              title: thread.title,
                              page: index + 1,
                              locked: thread.status == 'locked'));
                    },
                    child: Text(
                      '第 ${index + 1} 頁',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
