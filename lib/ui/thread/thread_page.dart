import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:hkgalden_flutter/secure_storage/token_secure_storage.dart';
import 'package:hkgalden_flutter/ui/common/compose_page.dart';
import 'package:hkgalden_flutter/ui/common/page_end_loading_indicator.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:hkgalden_flutter/ui/thread/comment_cell.dart';
import 'package:hkgalden_flutter/utils/keys.dart';
import 'package:hkgalden_flutter/viewmodels/thread_page_view_model.dart';
import 'package:marquee_widget/marquee_widget.dart';

class ThreadPage extends StatefulWidget {
  final String title;
  final int threadId;
  final int page;

  const ThreadPage({Key key, this.title, this.threadId, this.page})
      : super(key: key);

  @override
  _ThreadPageState createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage>
    with SingleTickerProviderStateMixin {
  ScrollController _scrollController;
  AnimationController _fabAnimationController;
  String _token;
  bool _onLastPage;

  @override
  void initState() {
    _scrollController = ScrollController();
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 150),
      reverseDuration: Duration(milliseconds: 75),
      value: 1,
      vsync: this,
    );
    //get token
    TokenSecureStorage().readToken(onFinish: (value) {
      setState(() {
        _token = value;
      });
    });
    _onLastPage = false;
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      StoreConnector<AppState, ThreadPageViewModel>(
        onInit: (store) {
          store.dispatch(RequestThreadAction(
              threadId: widget.threadId,
              page: widget.page,
              isInitialLoad: true));
          _scrollController
            ..addListener(() {
              if (_scrollController.position.pixels ==
                  _scrollController.position.maxScrollExtent) {
                if (!_onLastPage) {
                  store.dispatch(RequestThreadAction(
                    threadId: store.state.threadState.thread.threadId,
                    page: store.state.threadState.currentPage + 1,
                    isInitialLoad: false,
                  ));
                }
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
        onDidChange: (viewModel) {
          if ((viewModel.totalReplies.toDouble() / 50.0).ceil() >
              viewModel.currentPage) {
            setState(() {
              _onLastPage = false;
            });
          } else {
            setState(() {
              _onLastPage = true;
            });
          }
        },
        converter: (store) => ThreadPageViewModel.create(store),
        builder: (BuildContext context, ThreadPageViewModel viewModel) =>
            Scaffold(
                key: scaffoldKey,
                appBar: AppBar(
                  title: Marquee(
                    child: Text(widget.title.trim(),
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    animationDuration: Duration(seconds: 7),
                    pauseDuration: Duration(seconds: 1),
                    backDuration: Duration(seconds: 7),
                  ),
                  bottom: PreferredSize(
                    child: SizedBox(
                      height: 3,
                      child: Visibility(
                          visible:
                              viewModel.isLoading && !viewModel.isInitialLoad,
                          child: LinearProgressIndicator()),
                    ),
                    preferredSize: Size(double.infinity, 3),
                  ),
                ),
                body: viewModel.isLoading && viewModel.isInitialLoad
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : ListView(
                        controller: _scrollController,
                        children: _generateReplies(viewModel),
                      ),
                floatingActionButton: AnimatedBuilder(
                  animation: _fabAnimationController,
                  builder: (context, child) => FadeScaleTransition(
                    animation: _fabAnimationController,
                    child: child,
                  ),
                  child: FloatingActionButton(
                    child: Icon(Icons.reply),
                    onPressed: () => _token == ''
                        ? showModal<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('未登入'),
                              content: Text('請先登入'),
                              actions: <Widget>[
                                FlatButton(
                                  child: Text('OK'),
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          )
                        : Navigator.of(context).push(SlideInFromBottomRoute(
                            page: ComposePage(
                            composeMode: ComposeMode.reply,
                            threadId: viewModel.threadId,
                            onSent: (reply) {
                              _onReplySuccess(viewModel, reply);
                            },
                          ))),
                  ),
                )),
      );

  List<Widget> _generateReplies(ThreadPageViewModel viewModel) {
    List<Widget> repliesWidgets = [];
    for (Reply reply in viewModel.replies) {
      if (reply.floor % 50 == 1) {
        repliesWidgets.add(Container(
          height: 50,
          child: Center(
            child: Text(reply.floor == 1
                ? '第 1 頁'
                : '第 ${((reply.floor + 49) ~/ 50)} 頁'),
          ),
        ));
      }
      repliesWidgets.add(
        Visibility(
            visible: !viewModel.blockedUserIds.contains(reply.author.userId),
            child: CommentCell(
              viewModel: viewModel,
              threadId: viewModel.threadId,
              reply: reply,
              onLastPage: _onLastPage,
              onSent: (reply) {
                _onReplySuccess(viewModel, reply);
              },
            )),
      );
    }
    repliesWidgets.add(!_onLastPage
        ? PageEndLoadingInidicator()
        : Container(
            height: 50,
            child: Center(
              child: Text('已到post底', style: TextStyle(color: Colors.grey)),
            ),
          ));
    return repliesWidgets;
  }

  void _onReplySuccess(ThreadPageViewModel viewModel, Reply reply) {
    scaffoldKey.currentState.showSnackBar(SnackBar(content: Text('回覆發送成功!')));
    if (_onLastPage) {
      viewModel.appendReply(reply);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 500), curve: Curves.easeOut);
      });
    }
  }
}
