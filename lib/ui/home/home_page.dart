import 'dart:ui';

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
import 'package:hkgalden_flutter/viewmodels/home/home_page_view_model.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
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
        duration: Duration(milliseconds: 150),
        reverseDuration: Duration(milliseconds: 200),
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
                      title: Text.rich(
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
                          WidgetSpan(
                              child: SizedBox(
                            width: 5,
                          )),
                          TextSpan(
                              text: viewModel.title,
                              style: TextStyle(
                                  fontSize: 19, fontWeight: FontWeight.w700))
                        ]),
                      ),
                      actions: [
                        viewModel.isLoggedIn
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: PopupMenuButton(
                                    itemBuilder: (context) => [
                                          PopupMenuItem(
                                            child: ListTile(
                                              dense: true,
                                              leading: Icon(
                                                  Icons.account_box_rounded),
                                              title: Text('個人檔案'),
                                            ),
                                            value: _MenuItem.account,
                                          ),
                                          PopupMenuItem(
                                            child: ListTile(
                                              dense: true,
                                              leading:
                                                  Icon(Icons.block_rounded),
                                              title: Text('封鎖名單'),
                                            ),
                                            value: _MenuItem.blocklist,
                                          ),
                                          PopupMenuItem(
                                            child: ListTile(
                                              dense: true,
                                              leading:
                                                  Icon(Icons.copyright_rounded),
                                              title: Text('版權資訊'),
                                            ),
                                            value: _MenuItem.licences,
                                          ),
                                          PopupMenuItem(
                                            child: ListTile(
                                              dense: true,
                                              leading: Icon(
                                                Icons.logout,
                                                color: Colors.redAccent,
                                              ),
                                              title: Text('登出'),
                                            ),
                                            value: _MenuItem.logout,
                                          ),
                                        ],
                                    onSelected: (value) async {
                                      switch (value) {
                                        case _MenuItem.account:
                                          showMaterialModalBottomSheet(
                                              duration:
                                                  Duration(milliseconds: 200),
                                              animationCurve: Curves.easeOut,
                                              enableDrag: false,
                                              backgroundColor:
                                                  Colors.transparent,
                                              barrierColor: Colors.black87,
                                              context: context,
                                              builder: (context, controller) =>
                                                  UserPage(
                                                    user: viewModel.sessionUser,
                                                  ));
                                          break;
                                        case _MenuItem.blocklist:
                                          showMaterialModalBottomSheet(
                                              duration:
                                                  Duration(milliseconds: 200),
                                              animationCurve: Curves.easeOut,
                                              enableDrag: false,
                                              backgroundColor:
                                                  Colors.transparent,
                                              barrierColor: Colors.black87,
                                              context: context,
                                              builder: (context, controller) =>
                                                  BlockListPage());
                                          break;
                                        case _MenuItem.licences:
                                          PackageInfo info =
                                              await PackageInfo.fromPlatform();
                                          showLicensePage(
                                            context: context,
                                            applicationName: 'hkGalden',
                                            applicationIcon: SvgPicture.asset(
                                              'assets/icon-hkgalden.svg',
                                              width: 50,
                                              height: 50,
                                              color:
                                                  Theme.of(context).accentColor,
                                            ),
                                            applicationVersion:
                                                '${info.version}+${info.buildNumber}',
                                            applicationLegalese:
                                                '© hkGalden & 1080',
                                          );
                                          break;
                                        case _MenuItem.logout:
                                          viewModel.onLogout();
                                          break;
                                        default:
                                      }
                                    },
                                    icon: Icon(Icons.apps_rounded)),
                              )
                            : IconButton(
                                icon: Icon(Icons.login_rounded),
                                onPressed: () => Navigator.of(context).push(
                                    SlideInFromBottomRoute(page: LoginPage())))
                      ],
                    ),
                    preferredSize: Size.fromHeight(kToolbarHeight)),
                frontLayer: Theme(
                  data: Theme.of(context)
                      .copyWith(highlightColor: Color(0xff373d3c)),
                  child: Material(
                    color: Theme.of(context).primaryColor,
                    child: Container(
                      child: viewModel.isThreadLoading &&
                              viewModel.isRefresh == false
                          ? ListLoadingSkeleton()
                          : Theme.of(context).platform == TargetPlatform.iOS
                              ? CustomScrollView(
                                  controller: _scrollController,
                                  slivers: [
                                    CupertinoSliverRefreshControl(
                                      refreshTriggerPullDistance: 120,
                                      onRefresh: () => viewModel.onRefresh(
                                          viewModel.selectedChannelId),
                                    ),
                                    SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                            (context, index) {
                                      if (index == viewModel.threads.length) {
                                        return ListLoadingSkeletonCell();
                                      } else {
                                        return Visibility(
                                          visible: !viewModel.blockedUserIds
                                              .contains(viewModel.threads[index]
                                                  .replies[0].author.userId),
                                          child: ThreadCell(
                                            key: ValueKey(viewModel
                                                .threads[index].threadId),
                                            thread: viewModel.threads[index],
                                            onTap: () => _loadThread(
                                                viewModel.threads[index]),
                                            onLongPress: () => _jumpToPage(
                                                viewModel.threads[index]),
                                          ),
                                        );
                                      }
                                    },
                                            childCount:
                                                viewModel.threads.length + 1,
                                            addAutomaticKeepAlives: false,
                                            addRepaintBoundaries: false))
                                  ],
                                )
                              : RefreshIndicator(
                                  backgroundColor: Colors.white,
                                  strokeWidth: 2.5,
                                  child: ListView.builder(
                                    addAutomaticKeepAlives: false,
                                    addRepaintBoundaries: false,
                                    controller: _scrollController,
                                    itemCount: viewModel.threads.length + 1,
                                    itemBuilder: (context, index) {
                                      if (index == viewModel.threads.length) {
                                        return ListLoadingSkeletonCell();
                                      } else {
                                        return Visibility(
                                          visible: !viewModel.blockedUserIds
                                              .contains(viewModel.threads[index]
                                                  .replies[0].author.userId),
                                          child: ThreadCell(
                                            key: ValueKey(viewModel
                                                .threads[index].threadId),
                                            thread: viewModel.threads[index],
                                            onTap: () => _loadThread(
                                                viewModel.threads[index]),
                                            onLongPress: () => _jumpToPage(
                                                viewModel.threads[index]),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  onRefresh: () => viewModel
                                      .onRefresh(viewModel.selectedChannelId)),
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
                        child: Icon(Icons.create_rounded),
                        onPressed: () => viewModel.isLoggedIn
                            ? showBarModalBottomSheet(
                                duration: Duration(milliseconds: 300),
                                animationCurve: Curves.easeOut,
                                context: context,
                                builder: (context, controller) => ComposePage(
                                  composeMode: ComposeMode.newPost,
                                  onCreateThread: (channelId) =>
                                      viewModel.onCreateThread(channelId),
                                ),
                              )
                            : showCustomDialog(
                                context: context,
                                builder: (context) => CustomAlertDialog(
                                      title: '未登入',
                                      content: '請先登入',
                                    )),
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
        ),
      ),
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
      duration: Duration(milliseconds: 200),
      animationCurve: Curves.easeOut,
      enableDrag: false,
      barrierColor: Colors.black.withOpacity(0.5),
      context: context,
      builder: (context, controller) => Theme(
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
                    .headline6
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
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: SimpleDialogOption(
                    padding: EdgeInsets.all(16.0),
                    onPressed: () {
                      Navigator.of(context).pop();
                      navigatorKey.currentState.pushNamed('/Thread',
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
          progress: Backdrop.of(context).controller.view,
        ),
        onPressed: () => Backdrop.of(context).fling(),
      );
}

enum _MenuItem { account, blocklist, licences, logout }
