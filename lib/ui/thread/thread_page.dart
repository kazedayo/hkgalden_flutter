import 'package:animations/animations.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';
import 'package:hkgalden_flutter/ui/thread/comment_cell.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton_cell.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton_header.dart';
import 'package:hkgalden_flutter/utils/keys.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';
import 'package:hkgalden_flutter/viewmodels/thread_page_view_model.dart';

class ThreadPage extends StatefulWidget {
  @override
  _ThreadPageState createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  ScrollController _scrollController;
  bool _onLastPage;
  bool _canReply;
  bool _fabIsHidden;
  double _elevation;

  @override
  void initState() {
    //_scrollController = ScrollController();
    _onLastPage = false;
    _fabIsHidden = false;
    _elevation = 0.0;
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Key centerKey = ValueKey('second-sliver-list');
    final ThreadPageArguments arguments =
        ModalRoute.of(context).settings.arguments;
    return Scaffold(
      body: Builder(
        builder: (context) => StoreConnector<AppState, ThreadPageViewModel>(
          distinct: true,
          onInit: (store) {
            _canReply = store.state.sessionUserState.isLoggedIn;
            store.dispatch(RequestThreadAction(
                threadId: arguments.threadId,
                page: arguments.page,
                isInitialLoad: true));
            _scrollController = PrimaryScrollController.of(context);
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
                if (_scrollController.position.userScrollDirection ==
                        ScrollDirection.reverse &&
                    !_fabIsHidden) {
                  setState(() {
                    _fabIsHidden = true;
                  });
                } else if ((_scrollController.position.userScrollDirection ==
                            ScrollDirection.forward ||
                        _scrollController.position.pixels ==
                            _scrollController.position.maxScrollExtent ||
                        _scrollController.position.pixels == 0.0) &&
                    _fabIsHidden) {
                  setState(() {
                    _fabIsHidden = false;
                  });
                }
                double newElevation = _scrollController.position.pixels >
                        _scrollController.position.minScrollExtent
                    ? 4.0
                    : 0.0;
                if (newElevation != _elevation) {
                  setState(() {
                    _elevation = newElevation;
                  });
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
            resizeToAvoidBottomInset: false,
            key: scaffoldKey,
            appBar: PreferredSize(
                child: AppBar(
                  elevation: _elevation,
                  automaticallyImplyLeading: false,
                  leading: IconButton(
                      icon: Icon(
                          Theme.of(context).platform == TargetPlatform.iOS
                              ? Icons.arrow_back_ios
                              : Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop()),
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
                            maxFontSize: 19,
                            //overflow: TextOverflow.ellipsis
                          ),
                        )
                      ],
                    ),
                  ),
                  actions: [
                    Visibility(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: Icon(Icons.lock),
                        ),
                        visible: arguments.locked)
                  ],
                ),
                preferredSize: Size.fromHeight(kToolbarHeight)),
            body: viewModel.isLoading && viewModel.isInitialLoad
                ? ThreadPageLoadingSkeleton()
                : CustomScrollView(
                    center: centerKey,
                    controller: _scrollController,
                    slivers: <Widget>[
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _generatePreviousPageSliver(
                              viewModel, index, arguments.page);
                        },
                            childCount:
                                viewModel.previousPageReplies.length == 0
                                    ? 1
                                    : viewModel.previousPageReplies.length,
                            addAutomaticKeepAlives: false,
                            addRepaintBoundaries: false),
                      ),
                      SliverList(
                        key: centerKey,
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _generatePageSliver(viewModel, index);
                          },
                          childCount: viewModel.replies.length,
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: false,
                        ),
                      ),
                    ],
                  ),
            floatingActionButton: _fabIsHidden ||
                    viewModel.status == 'locked' ||
                    (viewModel.isLoading && viewModel.isInitialLoad)
                ? null
                : FloatingActionButton(
                    child: Icon(Icons.reply),
                    onPressed: () => !_canReply
                        ? showModal<void>(
                            context: context,
                            builder: (context) => CustomAlertDialog(
                                  title: '未登入',
                                  content: '請先登入',
                                ))
                        : Navigator.of(context).pushNamed('/Compose',
                            arguments: ComposePageArguments(
                              composeMode: ComposeMode.reply,
                              threadId: viewModel.threadId,
                              onSent: (reply) {
                                _onReplySuccess(viewModel, reply);
                              },
                            ))),
          ),
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
      return Visibility(
        visible: page != 1,
        child: ThreadPageLoadingSkeletonCell(),
      );
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
              ThreadPageLoadingSkeletonCell(),
            _PageHeader(
              floor: viewModel
                  .previousPageReplies[
                      viewModel.previousPageReplies.length - index - 1]
                  .floor,
            ),
            CommentCell(
              key: ValueKey(viewModel
                  .previousPageReplies[
                      viewModel.previousPageReplies.length - index - 1]
                  .replyId),
              threadId: viewModel.threadId,
              reply: viewModel.previousPageReplies[
                  viewModel.previousPageReplies.length - index - 1],
              onLastPage: _onLastPage,
              onSent: (reply) {
                _onReplySuccess(viewModel, reply);
              },
              canReply: _canReply,
              threadLocked: viewModel.status == 'locked',
            ),
          ],
        );
      } else {
        return CommentCell(
          key: ValueKey(viewModel
              .previousPageReplies[
                  viewModel.previousPageReplies.length - index - 1]
              .replyId),
          threadId: viewModel.threadId,
          reply: viewModel.previousPageReplies[
              viewModel.previousPageReplies.length - index - 1],
          onLastPage: _onLastPage,
          onSent: (reply) {
            _onReplySuccess(viewModel, reply);
          },
          canReply: _canReply,
          threadLocked: viewModel.status == 'locked',
        );
      }
    }
  }

  Widget _generatePageSliver(ThreadPageViewModel viewModel, int index) {
    if (viewModel.replies[index].floor % 50 == 1 &&
        viewModel.replies[index] == viewModel.replies.last) {
      return Column(
        children: <Widget>[
          _PageHeader(floor: viewModel.replies[index].floor),
          CommentCell(
            key: ValueKey(viewModel.replies[index].replyId),
            threadId: viewModel.threadId,
            reply: viewModel.replies[index],
            onLastPage: _onLastPage,
            onSent: (reply) {
              _onReplySuccess(viewModel, reply);
            },
            canReply: _canReply,
            threadLocked: viewModel.status == 'locked',
          ),
          _PageFooter(
            onLastPage: _onLastPage,
            isLoading: viewModel.isLoading,
            onTap: () => StoreProvider.of<AppState>(context).dispatch(
                RequestThreadAction(
                    threadId: viewModel.threadId,
                    page: viewModel.endPage,
                    isInitialLoad: false)),
          )
        ],
      );
    } else if (viewModel.replies[index].floor % 50 == 1 &&
        viewModel.replies.length != 1) {
      return Column(
        children: <Widget>[
          _PageHeader(floor: viewModel.replies[index].floor),
          CommentCell(
            key: ValueKey(viewModel.replies[index].replyId),
            threadId: viewModel.threadId,
            reply: viewModel.replies[index],
            onLastPage: _onLastPage,
            onSent: (reply) {
              _onReplySuccess(viewModel, reply);
            },
            canReply: _canReply,
            threadLocked: viewModel.status == 'locked',
          ),
        ],
      );
    } else if (index == viewModel.replies.length - 1) {
      return Column(
        children: <Widget>[
          CommentCell(
            key: ValueKey(viewModel.replies[index].replyId),
            threadId: viewModel.threadId,
            reply: viewModel.replies[index],
            onLastPage: _onLastPage,
            onSent: (reply) {
              _onReplySuccess(viewModel, reply);
            },
            canReply: _canReply,
            threadLocked: viewModel.status == 'locked',
          ),
          _PageFooter(
            onLastPage: _onLastPage,
            isLoading: viewModel.isLoading,
            onTap: () => StoreProvider.of<AppState>(context).dispatch(
                RequestThreadAction(
                    threadId: viewModel.threadId,
                    page: viewModel.endPage,
                    isInitialLoad: false)),
          ),
        ],
      );
    } else {
      return CommentCell(
        key: ValueKey(viewModel.replies[index].replyId),
        threadId: viewModel.threadId,
        reply: viewModel.replies[index],
        onLastPage: _onLastPage,
        onSent: (reply) {
          _onReplySuccess(viewModel, reply);
        },
        canReply: _canReply,
        threadLocked: viewModel.status == 'locked',
      );
    }
  }
}

class _PageHeader extends StatelessWidget {
  final int floor;

  const _PageHeader({Key key, this.floor}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        height: 50,
        child: Center(
          child: Text(floor == 1 ? '第 1 頁' : '第 ${((floor + 49) ~/ 50)} 頁'),
        ),
      );
}

class _PageFooter extends StatelessWidget {
  final bool onLastPage;
  final bool isLoading;
  final Function onTap;

  const _PageFooter({Key key, this.onLastPage, this.isLoading, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: !onLastPage
            ? ThreadPageLoadingSkeletonHeader()
            : Column(
                children: [
                  Container(
                    height: 85,
                    child: Center(
                      child: FlatButton.icon(
                          onPressed: () => onTap(),
                          icon: isLoading
                              ? ProgressSpinner()
                              : Icon(
                                  Icons.refresh,
                                  size: 25,
                                  color: Colors.grey,
                                ),
                          label: Text(
                            isLoading ? '撈緊...' : '重新整理',
                            style: Theme.of(context).textTheme.caption,
                            strutStyle:
                                StrutStyle(height: 1.1, forceStrutHeight: true),
                          )),
                    ),
                  ),
                ],
              ),
      );
}
