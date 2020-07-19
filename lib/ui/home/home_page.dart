import 'package:animations/animations.dart';
import 'package:backdrop/button.dart';
import 'package:backdrop/scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/thread_list/thread_list_action.dart';
import 'package:hkgalden_flutter/ui/common/compose_page.dart';
import 'package:hkgalden_flutter/ui/common/login_check_dialog.dart';
import 'package:hkgalden_flutter/ui/common/page_end_loading_indicator.dart';
import 'package:hkgalden_flutter/ui/home/drawer/home_drawer.dart';
import 'package:hkgalden_flutter/ui/home/list_loading_skeleton.dart';
import 'package:hkgalden_flutter/ui/home/thread_cell.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:hkgalden_flutter/utils/keys.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';
import 'package:hkgalden_flutter/viewmodels/home/home_page_view_model.dart';

class HomePage extends StatefulWidget {
  final String title;

  HomePage({Key key, this.title}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, HomePageViewModel>(
      converter: (store) => HomePageViewModel.create(store),
      distinct: true,
      onInit: (store) {
        _scrollController
          ..addListener(() {
            if (_scrollController.position.pixels ==
                _scrollController.position.maxScrollExtent) {
              store.dispatch(RequestThreadListAction(
                  channelId: store.state.threadListState.currentChannelId,
                  page: store.state.threadListState.currentPage + 1,
                  isRefresh: true));
            }
          });
      },
      builder: (BuildContext context, HomePageViewModel viewModel) =>
          WillPopScope(
        onWillPop: () async => false,
        child: BackdropScaffold(
          appBar: AppBar(
            leading: BackdropToggleButton(icon: AnimatedIcons.close_menu),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Hero(
                    tag: 'logo',
                    child: SizedBox(
                        child: SvgPicture.asset('assets/icon-hkgalden.svg'),
                        width: 27,
                        height: 27)),
                SizedBox(width: 5),
                Text(viewModel.title,
                    style: TextStyle(fontWeight: FontWeight.w700),
                    strutStyle: StrutStyle(height: 1.25)),
              ],
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.create),
                onPressed: () => viewModel.isLoggedIn
                    ? Navigator.of(context).pushNamed('/Compose',
                        arguments: ComposePageArguments(
                          composeMode: ComposeMode.newPost,
                          onCreateThread: (channelId) =>
                              viewModel.onCreateThread(channelId),
                        ))
                    : showModal<void>(
                        context: context,
                        builder: (context) => LoginCheckDialog()),
              )
            ],
          ),
          frontLayer: Material(
            color: Theme.of(context).primaryColor,
            child: Container(
              child: viewModel.isThreadLoading && viewModel.isRefresh == false
                  ? ListLoadingSkeleton()
                  : RefreshIndicator(
                      strokeWidth: 2.5,
                      onRefresh: () =>
                          viewModel.onRefresh(viewModel.selectedChannelId),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: viewModel.threads.length + 1,
                        itemBuilder: (context, index) {
                          if (index == viewModel.threads.length) {
                            return PageEndLoadingInidicator();
                          } else {
                            return Visibility(
                              visible: !viewModel.blockedUserIds.contains(
                                  viewModel
                                      .threads[index].replies[0].author.userId),
                              child: ThreadCell(
                                title: viewModel.threads[index].title,
                                authorName: viewModel
                                    .threads[index].replies[0].authorNickname,
                                totalReplies:
                                    viewModel.threads[index].totalReplies,
                                lastReply: viewModel
                                            .threads[index].replies.length ==
                                        2
                                    ? viewModel.threads[index].replies[1].date
                                    : viewModel.threads[index].replies[0].date,
                                tagName: viewModel.threads[index].tagName,
                                tagColor: viewModel.threads[index].tagColor,
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
          backLayerBackgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
