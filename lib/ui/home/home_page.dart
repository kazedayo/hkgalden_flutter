import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:backdrop/scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/thread_list/thread_list_action.dart';
import 'package:hkgalden_flutter/ui/common/login_check_dialog.dart';
import 'package:hkgalden_flutter/ui/home/drawer/home_drawer.dart';
import 'package:hkgalden_flutter/ui/home/skeletons/list_loading_skeleton.dart';
import 'package:hkgalden_flutter/ui/home/skeletons/list_loading_skeleton_cell.dart';
import 'package:hkgalden_flutter/ui/home/thread_cell.dart';
import 'package:hkgalden_flutter/ui/login_page.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:hkgalden_flutter/utils/keys.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';
import 'package:hkgalden_flutter/viewmodels/home/home_page_view_model.dart';
import 'package:package_info/package_info.dart';

class HomePage extends StatefulWidget {
  final String title;

  HomePage({Key key, this.title}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  ScrollController _scrollController;
  AnimationController _backgroundBlurAnimationController;
  bool _fabIsHidden;
  bool _menuIsShowing;

  @override
  void initState() {
    //_scrollController = ScrollController();
    _backgroundBlurAnimationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 250),
        value: 0.0,
        upperBound: 5.0)
      ..addStatusListener((status) {
        if (status == AnimationStatus.dismissed) {
          setState(() {
            _menuIsShowing = false;
          });
        }
      });
    _fabIsHidden = false;
    _menuIsShowing = false;
    showAfter();
    super.initState();
  }

  //hacky way to show status bar after hero finished
  Future<void> showAfter() async {
    await Future.delayed(Duration(milliseconds: 650), () {
      print('delay completed');
    });
    SystemChrome.setEnabledSystemUIOverlays(
        [SystemUiOverlay.top, SystemUiOverlay.bottom]);
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
    return Scaffold(
      body: Builder(
        builder: (context) => StoreConnector<AppState, HomePageViewModel>(
          converter: (store) => HomePageViewModel.create(store),
          distinct: true,
          onInit: (store) {
            _scrollController = PrimaryScrollController.of(context);
            _scrollController
              ..addListener(() {
                if (_scrollController.position.pixels ==
                    _scrollController.position.maxScrollExtent) {
                  store.dispatch(RequestThreadListAction(
                      channelId: store.state.threadListState.currentChannelId,
                      page: store.state.threadListState.currentPage + 1,
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
          },
          builder: (BuildContext context, HomePageViewModel viewModel) => Stack(
            fit: StackFit.expand,
            children: [
              BackdropScaffold(
                resizeToAvoidBottomInset: false,
                appBar: PreferredSize(
                    child: AppBar(
                      leading: _LeadingButton(),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Hero(
                              tag: 'logo',
                              child: SizedBox(
                                  child: SvgPicture.asset(
                                      'assets/icon-hkgalden.svg'),
                                  width: 27,
                                  height: 27)),
                          SizedBox(width: 5),
                          Text(viewModel.title,
                              style: TextStyle(fontWeight: FontWeight.w700),
                              strutStyle: StrutStyle(height: 1.25)),
                        ],
                      ),
                      actions: [
                        viewModel.isLoggedIn
                            ? PopupMenuButton(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5)),
                                icon: Icon(Icons.apps),
                                offset: Offset(0, kToolbarHeight - 20),
                                color: Colors.white,
                                onCanceled: () {
                                  _backgroundBlurAnimationController.reverse();
                                },
                                itemBuilder: (context) {
                                  setState(() {
                                    _menuIsShowing = true;
                                  });
                                  _backgroundBlurAnimationController.forward();
                                  return [
                                    PopupMenuItem(
                                        child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                            icon: Icon(
                                              Icons.account_box,
                                              color: Colors.black87,
                                            ),
                                            onPressed: () =>
                                                Navigator.of(context).pop()),
                                        IconButton(
                                            icon: Icon(
                                              Icons.settings,
                                              color: Colors.black87,
                                            ),
                                            onPressed: () async {
                                              Navigator.of(context).pop();
                                              PackageInfo info =
                                                  await PackageInfo
                                                      .fromPlatform();
                                              showModal(
                                                context: context,
                                                builder: (context) =>
                                                    AboutDialog(
                                                  applicationName: 'hkGalden',
                                                  applicationIcon:
                                                      SvgPicture.asset(
                                                    'assets/icon-hkgalden.svg',
                                                    width: 30,
                                                    height: 30,
                                                  ),
                                                  applicationVersion:
                                                      '${info.version}+${info.buildNumber}',
                                                  applicationLegalese:
                                                      '© hkGalden & 1080',
                                                ),
                                              );
                                            }),
                                        IconButton(
                                            icon: Icon(
                                              Icons.exit_to_app,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              viewModel.onLogout();
                                            }),
                                        IconButton(
                                            icon: Icon(
                                              Icons.block,
                                              color: Colors.black87,
                                            ),
                                            onPressed: () => null),
                                      ],
                                    ))
                                  ];
                                })
                            : IconButton(
                                icon: Icon(Icons.exit_to_app),
                                onPressed: () => Navigator.of(context).push(
                                    SlideInFromBottomRoute(page: LoginPage())))
                      ],
                    ),
                    preferredSize: Size.fromHeight(kToolbarHeight)),
                frontLayer: Material(
                  color: Theme.of(context).primaryColor,
                  child: Container(
                    child: viewModel.isThreadLoading &&
                            viewModel.isRefresh == false
                        ? ListLoadingSkeleton()
                        : RefreshIndicator(
                            strokeWidth: 2.5,
                            onRefresh: () => viewModel
                                .onRefresh(viewModel.selectedChannelId),
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: viewModel.threads.length + 1,
                              itemBuilder: (context, index) {
                                if (index == viewModel.threads.length) {
                                  return ListLoadingSkeletonCell();
                                } else {
                                  return Visibility(
                                    visible: !viewModel.blockedUserIds.contains(
                                        viewModel.threads[index].replies[0]
                                            .author.userId),
                                    child: ThreadCell(
                                      key: ValueKey(
                                          viewModel.threads[index].threadId),
                                      title: viewModel.threads[index].title,
                                      authorName: viewModel.threads[index]
                                          .replies[0].authorNickname,
                                      totalReplies:
                                          viewModel.threads[index].totalReplies,
                                      lastReply: viewModel.threads[index]
                                                  .replies.length ==
                                              2
                                          ? viewModel
                                              .threads[index].replies[1].date
                                          : viewModel
                                              .threads[index].replies[0].date,
                                      tagName: viewModel.threads[index].tagName,
                                      tagColor:
                                          viewModel.threads[index].tagColor,
                                      onTap: () =>
                                          _loadThread(viewModel.threads[index]),
                                      onLongPress: () =>
                                          _jumpToPage(viewModel.threads[index]),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                  ),
                ),
                inactiveOverlayColor: Colors.black,
                stickyFrontLayer: true,
                backLayer: HomeDrawer(),
                backLayerBackgroundColor:
                    Theme.of(context).scaffoldBackgroundColor,
                floatingActionButton: _fabIsHidden
                    ? null
                    : FloatingActionButton(
                        child: Icon(Icons.create),
                        onPressed: () => viewModel.isLoggedIn
                            ? navigatorKey.currentState.pushNamed('/Compose',
                                arguments: ComposePageArguments(
                                  composeMode: ComposeMode.newPost,
                                  onCreateThread: (channelId) =>
                                      viewModel.onCreateThread(channelId),
                                ))
                            : showModal<void>(
                                context: context,
                                builder: (context) => LoginCheckDialog()),
                      ),
              ),
              Visibility(
                visible: _menuIsShowing,
                child: AnimatedBuilder(
                  animation: _backgroundBlurAnimationController,
                  builder: (context, child) => BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Opacity(
                      opacity: _backgroundBlurAnimationController.value,
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _loadThread(Thread thread) {
    Navigator.of(context).pushNamed('/Thread',
        arguments: ThreadPageArguments(
            threadId: thread.threadId, title: thread.title, page: 1));
  }

  void _jumpToPage(Thread thread) {
    showModal<void>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('跳到頁數'),
        children: List.generate(
            (thread.replies.last.floor.toDouble() / 50.0).ceil(),
            (index) => SimpleDialogOption(
                  onPressed: () {
                    Navigator.of(context).pop();
                    navigatorKey.currentState.pushNamed('/Thread',
                        arguments: ThreadPageArguments(
                            threadId: thread.threadId,
                            title: thread.title,
                            page: index + 1));
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('第 ${index + 1} 頁'),
                  ),
                )),
      ),
    );
  }
}

class _LeadingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
        //visualDensity: VisualDensity.compact,
        icon: AnimatedIcon(
          icon: AnimatedIcons.close_menu,
          progress: Backdrop.of(context).controller.view,
        ),
        onPressed: () => Backdrop.of(context).fling(),
      );
}
