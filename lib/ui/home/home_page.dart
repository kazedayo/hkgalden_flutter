import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/store.dart';
import 'package:hkgalden_flutter/redux/thread_list/thread_list_action.dart';
import 'package:hkgalden_flutter/ui/common/page_end_loading_indicator.dart';
import 'package:hkgalden_flutter/ui/home/drawer/home_drawer.dart';
import 'package:hkgalden_flutter/ui/home/list_loading_skeleton.dart';
import 'package:hkgalden_flutter/ui/home/thread_cell.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page.dart';
import 'package:hkgalden_flutter/viewmodels/home_page_view_model.dart';

class HomePage extends StatefulWidget {
  final String title;

  HomePage({Key key, this.title}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  ScrollController _scrollController;
  AnimationController _fabAnimationController;

  @override
  void initState() {
    _scrollController = ScrollController();
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 150),
      reverseDuration: Duration(milliseconds: 75),
      value: 1,
      vsync: this,
    );
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
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
                  page: store.state.threadState.currentPage + 1,
                  isRefresh: true));
            }
          })
          ..addListener(() {
            if (_scrollController.position.userScrollDirection ==
                ScrollDirection.reverse) {
              _fabAnimationController.reverse();
            } else if (_scrollController.position.userScrollDirection ==
                ScrollDirection.forward) {
              _fabAnimationController.forward();
            }
          });
      },
      builder: (BuildContext context, HomePageViewModel viewModel) => Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Visibility(
                  visible: Theme.of(context).platform == TargetPlatform.iOS,
                  child: Spacer(flex: 1),
                ),
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
                Spacer(flex: 2),
              ],
            ),
          ),
          body: viewModel.isThreadLoading && viewModel.isRefresh == false
              ? /*Center(
                  child: CircularProgressIndicator(),
                )*/
              ListLoadingSkeleton()
              : RefreshIndicator(
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
                          visible: !viewModel.blockedUserIds.contains(viewModel
                              .threads[index].replies[0].author.userId),
                          child: ThreadCell(
                            title: viewModel.threads[index].title,
                            authorName: viewModel
                                .threads[index].replies[0].authorNickname,
                            totalReplies: viewModel.threads[index].totalReplies,
                            lastReply:
                                viewModel.threads[index].replies.length == 2
                                    ? viewModel.threads[index].replies[1].date
                                    : viewModel.threads[index].replies[0].date,
                            tagName: viewModel.threads[index].tagName,
                            tagColor: viewModel.threads[index].tagColor,
                            onTap: () => _loadThread(viewModel.threads[index]),
                            onLongPress: () =>
                                _jumpToPage(viewModel.threads[index]),
                          ),
                        );
                      }
                    },
                  ),
                ),
          drawer: HomeDrawer(),
          floatingActionButton: AnimatedBuilder(
            animation: _fabAnimationController,
            builder: (BuildContext context, Widget child) =>
                FadeScaleTransition(
              animation: _fabAnimationController,
              child: child,
            ),
            child: FloatingActionButton(
              onPressed: () => showModal<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Sorry!'),
                  content: Text('此功能尚未開放!'),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('OK'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              child: Icon(Icons.create),
            ),
          )),
    );
  }

  void _loadThread(Thread thread) {
    Navigator.of(context).push(CupertinoPageRoute(
        builder: (context) => ThreadPage(
            title: thread.title, threadId: thread.threadId, page: 1)));
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
                    Navigator.of(context).push(CupertinoPageRoute(
                        builder: (context) => ThreadPage(
                            title: thread.title,
                            threadId: thread.threadId,
                            page: index + 1)));
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
