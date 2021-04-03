import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/ui/common/compose_page.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';
import 'package:hkgalden_flutter/ui/thread/comment_cell.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton_cell.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton_header.dart';
import 'package:hkgalden_flutter/utils/keys.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class ThreadPage extends StatefulWidget {
  @override
  _ThreadPageState createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  late ScrollController _scrollController;
  late bool _onLastPage;
  late bool _canReply;
  late bool _fabIsHidden;
  late double _elevation;

  @override
  void initState() {
    _scrollController = ScrollController();
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
    final SessionUserBloc sessionUserBloc =
        BlocProvider.of<SessionUserBloc>(context);
    final ThreadPageArguments arguments =
        ModalRoute.of(context)!.settings.arguments! as ThreadPageArguments;
    _canReply = sessionUserBloc.state.isLoggedIn;
    return BlocProvider(
      create: (context) {
        final ThreadBloc threadBloc = ThreadBloc();
        threadBloc.add(RequestThreadEvent(
            threadId: arguments.threadId,
            page: arguments.page,
            isInitialLoad: true));
        _scrollController.addListener(() {
          if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent) {
            if (!_onLastPage) {
              threadBloc.add(RequestThreadEvent(
                  threadId: threadBloc.state.thread.threadId,
                  page: threadBloc.state.currentPage + 1,
                  isInitialLoad: false));
            }
          } else if (_scrollController.position.pixels ==
              _scrollController.position.minScrollExtent) {
            if (threadBloc.state.currentPage != 1 &&
                threadBloc.state.endPage <= arguments.page) {
              threadBloc.add(RequestThreadEvent(
                  threadId: threadBloc.state.thread.threadId,
                  page: threadBloc.state.currentPage - 1,
                  isInitialLoad: false));
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
          final double newElevation = _scrollController.position.pixels >
                  _scrollController.position.minScrollExtent
              ? 4.0
              : 0.0;
          if (newElevation != _elevation) {
            setState(() {
              _elevation = newElevation;
            });
          }
        });
        return threadBloc;
      },
      child: Scaffold(
        body: Builder(
          builder: (context) => BlocBuilder<ThreadBloc, ThreadState>(
            buildWhen: (prev, state) {
              if ((state.thread.totalReplies.toDouble() / 50.0).ceil() >
                  state.endPage) {
                setState(() {
                  _onLastPage = false;
                });
              } else {
                setState(() {
                  _onLastPage = true;
                });
              }
              return true;
            },
            builder: (context, state) => Scaffold(
              resizeToAvoidBottomInset: false,
              key: scaffoldKey,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: AppBar(
                  elevation: _elevation,
                  automaticallyImplyLeading: false,
                  leading: IconButton(
                      icon: Icon(
                          Theme.of(context).platform == TargetPlatform.iOS
                              ? Icons.arrow_back_ios_rounded
                              : Icons.arrow_back_rounded),
                      onPressed: () => Navigator.of(context).pop()),
                  title: SizedBox(
                    height: kToolbarHeight * 0.85,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Flexible(
                          child: AutoSizeText(
                            arguments.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
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
                      visible: arguments.locked,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 16.0),
                        child: Icon(Icons.lock_rounded),
                      ),
                    )
                  ],
                ),
              ),
              body: state.threadIsLoading && state.isInitialLoad
                  ? ThreadPageLoadingSkeleton()
                  : CustomScrollView(
                      center: centerKey,
                      controller: _scrollController,
                      slivers: <Widget>[
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                              (context, index) {
                            return _generatePreviousPageSliver(
                                state, index, arguments.page);
                          },
                              childCount: state.previousPages.replies.isEmpty
                                  ? 1
                                  : state.previousPages.replies.length,
                              addAutomaticKeepAlives: false,
                              addRepaintBoundaries: false),
                        ),
                        SliverList(
                          key: centerKey,
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _generatePageSliver(state, index);
                            },
                            childCount: state.thread.replies.length,
                            addAutomaticKeepAlives: false,
                            addRepaintBoundaries: false,
                          ),
                        ),
                      ],
                    ),
              floatingActionButton: _fabIsHidden ||
                      state.thread.status == 'locked' ||
                      (state.threadIsLoading && state.isInitialLoad)
                  ? null
                  : FloatingActionButton(
                      onPressed: () => !_canReply
                          ? showCustomDialog(
                              context: context,
                              builder: (context) => const CustomAlertDialog(
                                    title: '未登入',
                                    content: '請先登入',
                                  ))
                          : showBarModalBottomSheet(
                              duration: const Duration(milliseconds: 300),
                              animationCurve: Curves.easeOut,
                              context: context,
                              builder: (context) => ComposePage(
                                composeMode: ComposeMode.reply,
                                threadId: state.thread.threadId,
                                onSent: (reply) {
                                  _onReplySuccess(
                                      BlocProvider.of<ThreadBloc>(context),
                                      reply);
                                },
                              ),
                            ),
                      child: const Icon(Icons.reply_rounded),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  void _onReplySuccess(ThreadBloc threadBloc, Reply reply) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('回覆發送成功!')));
    if (_onLastPage) {
      threadBloc.add(AppendReplyToThreadEvent(reply: reply));
      SchedulerBinding.instance!.addPostFrameCallback((_) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
      });
    }
  }

  Widget _generatePreviousPageSliver(ThreadState state, int index, int page) {
    if (state.previousPages.replies.isEmpty) {
      return Visibility(
        visible: page != 1,
        child: ThreadPageLoadingSkeletonCell(),
      );
    } else {
      if (state
                  .previousPages
                  .replies[state.previousPages.replies.length - index - 1]
                  .floor %
              50 ==
          1) {
        return Column(
          children: <Widget>[
            if (state
                        .previousPages
                        .replies[state.previousPages.replies.length - index - 1]
                        .floor !=
                    1 &&
                (state
                                .previousPages
                                .replies[state.previousPages.replies.length -
                                    index -
                                    1]
                                .floor /
                            50.0)
                        .ceil() ==
                    state.currentPage)
              ThreadPageLoadingSkeletonCell(),
            _PageHeader(
              floor: state
                  .previousPages
                  .replies[state.previousPages.replies.length - index - 1]
                  .floor,
            ),
            CommentCell(
              key: ValueKey(state
                  .previousPages
                  .replies[state.previousPages.replies.length - index - 1]
                  .replyId),
              threadId: state.thread.threadId,
              reply: state.previousPages
                  .replies[state.previousPages.replies.length - index - 1],
              onLastPage: _onLastPage,
              onSent: (reply) {
                _onReplySuccess(BlocProvider.of<ThreadBloc>(context), reply);
              },
              canReply: _canReply,
              threadLocked: state.thread.status == 'locked',
            ),
          ],
        );
      } else {
        return CommentCell(
          key: ValueKey(state.previousPages
              .replies[state.previousPages.replies.length - index - 1].replyId),
          threadId: state.thread.threadId,
          reply: state.previousPages
              .replies[state.previousPages.replies.length - index - 1],
          onLastPage: _onLastPage,
          onSent: (reply) {
            _onReplySuccess(BlocProvider.of<ThreadBloc>(context), reply);
          },
          canReply: _canReply,
          threadLocked: state.thread.status == 'locked',
        );
      }
    }
  }

  Widget _generatePageSliver(ThreadState state, int index) {
    if (state.thread.replies[index].floor % 50 == 1 &&
        state.thread.replies[index] == state.thread.replies.last) {
      return Column(
        children: <Widget>[
          _PageHeader(floor: state.thread.replies[index].floor),
          CommentCell(
            key: ValueKey(state.thread.replies[index].replyId),
            threadId: state.thread.threadId,
            reply: state.thread.replies[index],
            onLastPage: _onLastPage,
            onSent: (reply) {
              _onReplySuccess(BlocProvider.of<ThreadBloc>(context), reply);
            },
            canReply: _canReply,
            threadLocked: state.thread.status == 'locked',
          ),
          _PageFooter(
            onLastPage: _onLastPage,
            isLoading: state.threadIsLoading,
            onTap: () => BlocProvider.of<ThreadBloc>(context).add(
                RequestThreadEvent(
                    threadId: state.thread.threadId,
                    page: state.endPage,
                    isInitialLoad: false)),
          )
        ],
      );
    } else if (state.thread.replies[index].floor % 50 == 1 &&
        state.thread.replies.length != 1) {
      return Column(
        children: <Widget>[
          _PageHeader(floor: state.thread.replies[index].floor),
          CommentCell(
            key: ValueKey(state.thread.replies[index].replyId),
            threadId: state.thread.threadId,
            reply: state.thread.replies[index],
            onLastPage: _onLastPage,
            onSent: (reply) {
              _onReplySuccess(BlocProvider.of<ThreadBloc>(context), reply);
            },
            canReply: _canReply,
            threadLocked: state.thread.status == 'locked',
          ),
        ],
      );
    } else if (index == state.thread.replies.length - 1) {
      return Column(
        children: <Widget>[
          CommentCell(
            key: ValueKey(state.thread.replies[index].replyId),
            threadId: state.thread.threadId,
            reply: state.thread.replies[index],
            onLastPage: _onLastPage,
            onSent: (reply) {
              _onReplySuccess(BlocProvider.of<ThreadBloc>(context), reply);
            },
            canReply: _canReply,
            threadLocked: state.thread.status == 'locked',
          ),
          _PageFooter(
            onLastPage: _onLastPage,
            isLoading: state.threadIsLoading,
            onTap: () => BlocProvider.of<ThreadBloc>(context).add(
                RequestThreadEvent(
                    threadId: state.thread.threadId,
                    page: state.endPage,
                    isInitialLoad: false)),
          ),
        ],
      );
    } else {
      return CommentCell(
        key: ValueKey(state.thread.replies[index].replyId),
        threadId: state.thread.threadId,
        reply: state.thread.replies[index],
        onLastPage: _onLastPage,
        onSent: (reply) {
          _onReplySuccess(BlocProvider.of<ThreadBloc>(context), reply);
        },
        canReply: _canReply,
        threadLocked: state.thread.status == 'locked',
      );
    }
  }
}

class _PageHeader extends StatelessWidget {
  final int floor;

  const _PageHeader({Key? key, required this.floor}) : super(key: key);

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 50,
        child: Center(
          child: Text(floor == 1 ? '第 1 頁' : '第 ${(floor + 49) ~/ 50} 頁'),
        ),
      );
}

class _PageFooter extends StatelessWidget {
  final bool onLastPage;
  final bool isLoading;
  final Function onTap;

  const _PageFooter(
      {Key? key,
      required this.onLastPage,
      required this.isLoading,
      required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: !onLastPage
            ? ThreadPageLoadingSkeletonHeader()
            : Column(
                children: [
                  SizedBox(
                    height: 85,
                    child: Center(
                      child: TextButton.icon(
                          clipBehavior: Clip.hardEdge,
                          onPressed: () => onTap(),
                          icon: isLoading
                              ? const ProgressSpinner()
                              : const Icon(
                                  Icons.refresh,
                                  size: 25,
                                  color: Colors.grey,
                                ),
                          label: Text(
                            isLoading ? '撈緊...' : '重新整理',
                            style: Theme.of(context).textTheme.caption,
                            strutStyle: const StrutStyle(
                                height: 1.1, forceStrutHeight: true),
                          )),
                    ),
                  ),
                ],
              ),
      );
}
