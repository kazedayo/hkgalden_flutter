import 'package:animations/animations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/store.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:hkgalden_flutter/secure_storage/token_secure_storage.dart';
import 'package:hkgalden_flutter/ui/common/compose_page.dart';
import 'package:hkgalden_flutter/ui/common/login_check_dialog.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:hkgalden_flutter/ui/thread/comment_cell.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_loading_skeleton.dart';
import 'package:hkgalden_flutter/utils/keys.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';
import 'package:hkgalden_flutter/viewmodels/thread_page_view_model.dart';

class ThreadPage extends StatefulWidget {
  @override
  _ThreadPageState createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage>
    with SingleTickerProviderStateMixin {
  ScrollController _scrollController;
  AnimationController _fabAnimationController;
  bool _onLastPage;
  bool _canReply;

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
        _canReply = value == '' ? false : true;
      });
    });
    _onLastPage = false;
    super.initState();
  }

  @override
  void deactivate() {
    store.dispatch(ClearThreadStateAction());
    super.deactivate();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Key centerKey = ValueKey('second-sliver-list');
    final ThreadPageArguments arguments =
        ModalRoute.of(context).settings.arguments;
    return StoreConnector<AppState, ThreadPageViewModel>(
      onInit: (store) {
        store.dispatch(RequestThreadAction(
            threadId: arguments.threadId,
            page: arguments.page,
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
            } else if (_scrollController.position.pixels ==
                _scrollController.position.minScrollExtent) {
              if (store.state.threadState.currentPage != 1 &&
                  store.state.threadState.endPage <= arguments.page) {
                store.dispatch(
                  RequestThreadAction(
                      threadId: store.state.threadState.thread.threadId,
                      page: store.state.threadState.currentPage - 1,
                      isInitialLoad: false),
                );
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
            viewModel.endPage) {
          setState(() {
            _onLastPage = false;
          });
        } else {
          setState(() {
            _onLastPage = true;
          });
        }
      },
      onDispose: (store) => store.dispatch(ClearThreadStateAction()),
      converter: (store) => ThreadPageViewModel.create(store),
      builder: (BuildContext context, ThreadPageViewModel viewModel) =>
          Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          title: SizedBox(
            height: kToolbarHeight * 0.85,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Flexible(
                  fit: FlexFit.loose,
                  child: AutoSizeText(
                    arguments.title,
                    style: TextStyle(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    minFontSize: 14,
                    //overflow: TextOverflow.ellipsis
                  ),
                )
              ],
            ),
          ),
        ),
        body: viewModel.isLoading && viewModel.isInitialLoad
            ? ThreadPageLoadingSkeleton()
            : //ListView.builder(
            //     controller: _scrollController,
            //     itemCount: viewModel.replies.length,
            //     itemBuilder: (context, index) =>
            //         _generatePageSliver(viewModel, index),
            //   ),
            SafeArea(
                top: false,
                child: CustomScrollView(
                  center: centerKey,
                  controller: _scrollController,
                  slivers: <Widget>[
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return _generatePreviousPageSliver(
                            viewModel, index, arguments.page);
                      },
                          childCount: viewModel.previousPageReplies.length == 0
                              ? 1
                              : viewModel.previousPageReplies.length),
                    ),
                    SliverList(
                      key: centerKey,
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return _generatePageSliver(viewModel, index);
                      }, childCount: viewModel.replies.length),
                    ),
                  ],
                ),
              ),
        floatingActionButton: AnimatedBuilder(
          animation: _fabAnimationController,
          builder: (context, child) => FadeScaleTransition(
            animation: _fabAnimationController,
            child: child,
          ),
          child: FloatingActionButton(
              child: Icon(Icons.reply),
              onPressed: () => !_canReply
                  ? showModal<void>(
                      context: context,
                      builder: (context) => LoginCheckDialog())
                  : Navigator.of(context).push(SlideInFromBottomRoute(
                      page: ComposePage(
                      composeMode: ComposeMode.reply,
                      threadId: viewModel.threadId,
                      onSent: (reply) {
                        _onReplySuccess(viewModel, reply);
                      },
                    )))),
        ),
      ),
    );
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

  Widget _generatePreviousPageSliver(
      ThreadPageViewModel viewModel, int index, int page) {
    if (viewModel.previousPageReplies.isEmpty) {
      if (page != 1) {
        return Container(
          height: 50,
          child: Center(
            child: Text('撈緊上一頁...', style: TextStyle(color: Colors.grey)),
          ),
        );
      } else {
        return SizedBox();
      }
    } else {
      if (viewModel
                  .previousPageReplies[
                      viewModel.previousPageReplies.length - index - 1]
                  .floor %
              50 ==
          1) {
        return Column(
          children: <Widget>[
            if (viewModel
                        .previousPageReplies[
                            viewModel.previousPageReplies.length - index - 1]
                        .floor !=
                    1 &&
                (viewModel
                                .previousPageReplies[
                                    viewModel.previousPageReplies.length -
                                        index -
                                        1]
                                .floor /
                            50.0)
                        .ceil() ==
                    viewModel.currentPage)
              Container(
                height: 50,
                child: Center(
                  child: Text('撈緊上一頁...', style: TextStyle(color: Colors.grey)),
                ),
              ),
            Container(
              height: 50,
              child: Center(
                child: Text(viewModel
                            .previousPageReplies[
                                viewModel.previousPageReplies.length -
                                    index -
                                    1]
                            .floor ==
                        1
                    ? '第 1 頁'
                    : '第 ${((viewModel.previousPageReplies[viewModel.previousPageReplies.length - index - 1].floor + 49) ~/ 50)} 頁'),
              ),
            ),
            Visibility(
                visible: !viewModel.blockedUserIds.contains(viewModel
                    .previousPageReplies[
                        viewModel.previousPageReplies.length - index - 1]
                    .author
                    .userId),
                child: CommentCell(
                  viewModel: viewModel,
                  threadId: viewModel.threadId,
                  reply: viewModel.previousPageReplies[
                      viewModel.previousPageReplies.length - index - 1],
                  onLastPage: _onLastPage,
                  onSent: (reply) {
                    _onReplySuccess(viewModel, reply);
                  },
                  canReply: _canReply,
                )),
          ],
        );
      } else {
        return Visibility(
            visible: !viewModel.blockedUserIds.contains(viewModel
                .previousPageReplies[
                    viewModel.previousPageReplies.length - index - 1]
                .author
                .userId),
            child: CommentCell(
              viewModel: viewModel,
              threadId: viewModel.threadId,
              reply: viewModel.previousPageReplies[
                  viewModel.previousPageReplies.length - index - 1],
              onLastPage: _onLastPage,
              onSent: (reply) {
                _onReplySuccess(viewModel, reply);
              },
              canReply: _canReply,
            ));
      }
    }
  }

  Widget _generatePageSliver(ThreadPageViewModel viewModel, int index) {
    if (viewModel.replies[index].floor % 50 == 1 &&
        viewModel.replies.length != 1) {
      return Column(
        children: <Widget>[
          Container(
            height: 50,
            child: Center(
              child: Text(viewModel.replies[index].floor == 1
                  ? '第 1 頁'
                  : '第 ${((viewModel.replies[index].floor + 49) ~/ 50)} 頁'),
            ),
          ),
          Visibility(
              visible: !viewModel.blockedUserIds
                  .contains(viewModel.replies[index].author.userId),
              child: CommentCell(
                viewModel: viewModel,
                threadId: viewModel.threadId,
                reply: viewModel.replies[index],
                onLastPage: _onLastPage,
                onSent: (reply) {
                  _onReplySuccess(viewModel, reply);
                },
                canReply: _canReply,
              )),
        ],
      );
    } else if (viewModel.replies[index].floor % 50 == 1 &&
        viewModel.replies.length == 1) {
      return Column(
        children: <Widget>[
          Container(
            height: 50,
            child: Center(
              child: Text(viewModel.replies[index].floor == 1
                  ? '第 1 頁'
                  : '第 ${((viewModel.replies[index].floor + 49) ~/ 50)} 頁'),
            ),
          ),
          Visibility(
              visible: !viewModel.blockedUserIds
                  .contains(viewModel.replies[index].author.userId),
              child: CommentCell(
                viewModel: viewModel,
                threadId: viewModel.threadId,
                reply: viewModel.replies[index],
                onLastPage: _onLastPage,
                onSent: (reply) {
                  _onReplySuccess(viewModel, reply);
                },
                canReply: _canReply,
              )),
          Container(
            height: 50,
            child: Center(
              child: Text('已到post底', style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      );
    } else if (index == viewModel.replies.length - 1) {
      return Column(
        children: <Widget>[
          Visibility(
              visible: !viewModel.blockedUserIds
                  .contains(viewModel.replies[index].author.userId),
              child: CommentCell(
                viewModel: viewModel,
                threadId: viewModel.threadId,
                reply: viewModel.replies[index],
                onLastPage: _onLastPage,
                onSent: (reply) {
                  _onReplySuccess(viewModel, reply);
                },
                canReply: _canReply,
              )),
          !_onLastPage
              ? Container(
                  height: 50,
                  child: Center(
                    child:
                        Text('撈緊下一頁...', style: TextStyle(color: Colors.grey)),
                  ),
                )
              : Container(
                  height: 50,
                  child: Center(
                    child:
                        Text('已到post底', style: TextStyle(color: Colors.grey)),
                  ),
                ),
        ],
      );
    } else {
      return Visibility(
          visible: !viewModel.blockedUserIds
              .contains(viewModel.replies[index].author.userId),
          child: CommentCell(
            viewModel: viewModel,
            threadId: viewModel.threadId,
            reply: viewModel.replies[index],
            onLastPage: _onLastPage,
            onSent: (reply) {
              _onReplySuccess(viewModel, reply);
            },
            canReply: _canReply,
          ));
    }
  }
}
