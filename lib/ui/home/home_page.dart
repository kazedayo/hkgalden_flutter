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
import 'package:hkgalden_flutter/ui/home/thread_cell.dart';
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
        _scrollController..addListener(() {
        if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
            store.dispatch(
            RequestThreadListAction(
                channelId: store.state.threadListState.currentChannelId, 
                page: store.state.threadState.currentPage + 1, 
                isRefresh: true
              )
            );
          }
        })..addListener(() {
          if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
            _fabAnimationController.reverse();
          } else if (_scrollController.position.userScrollDirection == ScrollDirection.forward) {
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
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : RefreshIndicator(
                  onRefresh: () =>
                      viewModel.onRefresh(viewModel.selectedChannelId),
                  child: ListView(
                    controller: _scrollController,
                    children: _generateThreads(viewModel),
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

  List<Widget> _generateThreads(HomePageViewModel viewModel) {
    List<Widget> threadCells = [];
    for (Thread thread in store.state.threadListState.threads)
      threadCells.add(Visibility(
        visible:
            !viewModel.blockedUserIds.contains(thread.replies[0].author.userId),
        child: ThreadCell(
          title: thread.title,
          authorName: thread.replies[0].authorNickname,
          totalReplies: thread.totalReplies,
          lastReply: thread.replies.length == 2
              ? thread.replies[1].date
              : thread.replies[0].date,
          onTap: () => viewModel.loadThread(context, thread),
          onLongPress: () => viewModel.jumpToPage(context, thread),
        ),
      ));
    threadCells.add(PageEndLoadingInidicator());
    return threadCells;
  }
}
