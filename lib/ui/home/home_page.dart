import 'dart:ui';

import 'package:backdrop/scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hkgalden_flutter/bloc/channel/channel_bloc.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_state.dart';
import 'package:hkgalden_flutter/bloc/thread_list/thread_list_bloc.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/secure_storage/token_secure_storage.dart';
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
    final SessionUserBloc sessionUserBloc =
        BlocProvider.of<SessionUserBloc>(context);
    final ThreadListBloc threadListBloc =
        BlocProvider.of<ThreadListBloc>(context);
    final ChannelBloc channelBloc = BlocProvider.of<ChannelBloc>(context);
    return BlocBuilder<ThreadListBloc, ThreadListState>(
      builder: (context, state) {
        _scrollController.addListener(() {
          if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent) {
            BlocProvider.of<ThreadListBloc>(context).add(RequestThreadListEvent(
                channelId: state.currentChannelId,
                page: state.currentPage,
                isRefresh: true));
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
        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              BlocBuilder<SessionUserBloc, SessionUserState>(
                builder: (context, state) => BackdropScaffold(
                  resizeToAvoidBottomInset: false,
                  appBar: PreferredSize(
                    preferredSize: const Size.fromHeight(kToolbarHeight),
                    child: AppBar(
                      leading: _LeadingButton(),
                      title: BlocBuilder<ChannelBloc, ChannelState>(
                        builder: (context, state) => Text.rich(
                          TextSpan(children: [
                            WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Hero(
                                    tag: 'logo',
                                    child: SvgPicture.asset(
                                      'assets/icon-hkgalden.svg',
                                      width: 27,
                                      height: 27,
                                    ))),
                            const WidgetSpan(
                                child: SizedBox(
                              width: 5,
                            )),
                            TextSpan(
                                text: state.channels
                                    .where((channel) =>
                                        channel.channelId ==
                                        state.selectedChannelId)
                                    .first
                                    .channelName,
                                style: const TextStyle(
                                    fontSize: 19, fontWeight: FontWeight.w700))
                          ]),
                        ),
                      ),
                      actions: [
                        if (state.isLoggedIn)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: PopupMenuButton(
                                itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: _MenuItem.account,
                                        child: ListTile(
                                          dense: true,
                                          leading:
                                              Icon(Icons.account_box_rounded),
                                          title: Text('個人檔案'),
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: _MenuItem.blocklist,
                                        child: ListTile(
                                          dense: true,
                                          leading: Icon(Icons.block_rounded),
                                          title: Text('封鎖名單'),
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: _MenuItem.licences,
                                        child: ListTile(
                                          dense: true,
                                          leading:
                                              Icon(Icons.copyright_rounded),
                                          title: Text('版權資訊'),
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: _MenuItem.logout,
                                        child: ListTile(
                                          dense: true,
                                          leading: Icon(
                                            Icons.logout,
                                            color: Colors.redAccent,
                                          ),
                                          title: Text('登出'),
                                        ),
                                      ),
                                    ],
                                onSelected: (value) async {
                                  switch (value! as _MenuItem) {
                                    case _MenuItem.account:
                                      showMaterialModalBottomSheet(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          animationCurve: Curves.easeOut,
                                          enableDrag: false,
                                          backgroundColor: Colors.transparent,
                                          barrierColor: Colors.black87,
                                          context: context,
                                          builder: (context) => UserPage(
                                                user: state.sessionUser,
                                              ));
                                      break;
                                    case _MenuItem.blocklist:
                                      showMaterialModalBottomSheet(
                                          duration:
                                              const Duration(milliseconds: 200),
                                          animationCurve: Curves.easeOut,
                                          enableDrag: false,
                                          backgroundColor: Colors.transparent,
                                          barrierColor: Colors.black87,
                                          context: context,
                                          builder: (context) =>
                                              BlockListPage());
                                      break;
                                    case _MenuItem.licences:
                                      final PackageInfo info =
                                          await PackageInfo.fromPlatform();
                                      showLicensePage(
                                        context: context,
                                        applicationName: 'hkGalden',
                                        applicationIcon: SvgPicture.asset(
                                          'assets/icon-hkgalden.svg',
                                          width: 50,
                                          height: 50,
                                          color: Theme.of(context).accentColor,
                                        ),
                                        applicationVersion:
                                            '${info.version}+${info.buildNumber}',
                                        applicationLegalese:
                                            '© hkGalden & 1080',
                                      );
                                      break;
                                    case _MenuItem.logout:
                                      TokenSecureStorage().writeToken('',
                                          onFinish: (_) {
                                        sessionUserBloc
                                            .add(RemoveSessionUserEvent());
                                        threadListBloc.add(
                                            RequestThreadListEvent(
                                                channelId: channelBloc
                                                    .state.selectedChannelId,
                                                page: 1,
                                                isRefresh: false));
                                      });
                                      break;
                                    default:
                                  }
                                },
                                icon: const Icon(Icons.apps_rounded)),
                          )
                        else
                          IconButton(
                              icon: const Icon(Icons.login_rounded),
                              onPressed: () => Navigator.of(context).push(
                                  SlideInFromBottomRoute(page: LoginPage())))
                      ],
                    ),
                  ),
                  frontLayer: Theme(
                    data: Theme.of(context)
                        .copyWith(highlightColor: const Color(0xff373d3c)),
                    child: Material(
                      color: Theme.of(context).primaryColor,
                      child: BlocBuilder<ThreadListBloc, ThreadListState>(
                        builder: (context, state) => RefreshIndicator(
                          backgroundColor: Colors.white,
                          strokeWidth: 2.5,
                          onRefresh: () async => threadListBloc.add(
                              RequestThreadListEvent(
                                  channelId:
                                      channelBloc.state.selectedChannelId,
                                  page: 1,
                                  isRefresh: true)),
                          child: state.threadListIsLoading
                              ? ListLoadingSkeleton()
                              : ListView.builder(
                                  addAutomaticKeepAlives: false,
                                  addRepaintBoundaries: false,
                                  controller: _scrollController,
                                  itemCount: state.threads.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == state.threads.length) {
                                      return ListLoadingSkeletonCell();
                                    } else {
                                      return BlocBuilder<SessionUserBloc,
                                          SessionUserState>(
                                        builder: (context, state) => Visibility(
                                          visible: !state
                                              .sessionUser.blockedUsers
                                              .contains(threadListBloc
                                                  .state
                                                  .threads[index]
                                                  .replies[0]
                                                  .author
                                                  .userId),
                                          child: BlocBuilder<ThreadListBloc,
                                              ThreadListState>(
                                            builder: (context, state) =>
                                                ThreadCell(
                                              key: ValueKey(state
                                                  .threads[index].threadId),
                                              thread: state.threads[index],
                                              onTap: () => _loadThread(
                                                  state.threads[index]),
                                              onLongPress: () => _jumpToPage(
                                                  state.threads[index]),
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                        ),
                      ),
                    ),
                  ),
                  frontLayerScrim: Colors.black.withAlpha(177),
                  stickyFrontLayer: true,
                  backLayer: HomeDrawer(),
                  backLayerBackgroundColor:
                      Theme.of(context).scaffoldBackgroundColor,
                  floatingActionButton: _fabIsHidden
                      ? null
                      : BlocBuilder<SessionUserBloc, SessionUserState>(
                          builder: (context, state) => FloatingActionButton(
                            onPressed: () => state.isLoggedIn
                                ? showBarModalBottomSheet(
                                    duration: const Duration(milliseconds: 300),
                                    animationCurve: Curves.easeOut,
                                    context: context,
                                    builder: (context) => ComposePage(
                                      composeMode: ComposeMode.newPost,
                                      onCreateThread: (channelId) =>
                                          threadListBloc.add(
                                              RequestThreadListEvent(
                                                  channelId: channelId,
                                                  page: 1,
                                                  isRefresh: false)),
                                    ),
                                  )
                                : showCustomDialog(
                                    context: context,
                                    builder: (context) =>
                                        const CustomAlertDialog(
                                          title: '未登入',
                                          content: '請先登入',
                                        )),
                            child: const Icon(Icons.create_rounded),
                          ),
                        ),
                ),
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

class _LeadingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
        icon: AnimatedIcon(
          icon: AnimatedIcons.close_menu,
          progress: Backdrop.of(context).animationController.view,
        ),
        onPressed: () => Backdrop.of(context).fling(),
      );
}

enum _MenuItem { account, blocklist, licences, logout }
