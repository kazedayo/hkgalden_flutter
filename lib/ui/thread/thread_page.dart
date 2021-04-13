import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/repository/thread_repository.dart';
import 'package:hkgalden_flutter/ui/common/compose_page.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';
import 'package:hkgalden_flutter/ui/thread/comment_cell.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton_cell.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton_header.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

part 'widgets/thread_page_app_bar.dart';
part 'widgets/thread_page_fab.dart';
part 'widgets/thread_page_previous_sliver.dart';
part 'widgets/thread_page_sliver.dart';
part 'widgets/thread_page_header.dart';
part 'widgets/thread_page_footer.dart';

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
    _canReply = sessionUserBloc.state is SessionUserLoaded;
    return RepositoryProvider(
      create: (context) => ThreadRepository(),
      child: BlocProvider(
        create: (context) {
          final ThreadBloc threadBloc = ThreadBloc(
              repository: RepositoryProvider.of<ThreadRepository>(context));
          threadBloc.add(RequestThreadEvent(
              threadId: arguments.threadId,
              page: arguments.page,
              isInitialLoad: true));
          _scrollController.addListener(() {
            if (_scrollController.position.pixels ==
                _scrollController.position.maxScrollExtent) {
              if (!_onLastPage) {
                threadBloc.add(RequestThreadEvent(
                    threadId:
                        (threadBloc.state as ThreadLoaded).thread.threadId,
                    page: (threadBloc.state as ThreadLoaded).currentPage + 1,
                    isInitialLoad: false));
              }
            } else if (_scrollController.position.pixels ==
                _scrollController.position.minScrollExtent) {
              if ((threadBloc.state as ThreadLoaded).currentPage != 1 &&
                  (threadBloc.state as ThreadLoaded).endPage <=
                      arguments.page) {
                threadBloc.add(RequestThreadEvent(
                    threadId:
                        (threadBloc.state as ThreadLoaded).thread.threadId,
                    page: (threadBloc.state as ThreadLoaded).currentPage - 1,
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
          body: BlocConsumer<ThreadBloc, ThreadState>(
            listener: (context, state) {
              if (state is ThreadLoaded) {
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
              }
            },
            buildWhen: (_, state) => state is! ThreadAppending,
            builder: (context, state) {
              return Scaffold(
                resizeToAvoidBottomInset: false,
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: _buildAppBar(context, arguments, _elevation),
                ),
                body: state is ThreadLoading
                    ? ThreadPageLoadingSkeleton()
                    : () {
                        if (state is ThreadLoaded) {
                          return CustomScrollView(
                            center: centerKey,
                            controller: _scrollController,
                            slivers: <Widget>[
                              SliverList(
                                delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                  return _generatePreviousPageSliver(
                                      state,
                                      index,
                                      arguments.page,
                                      _onLastPage,
                                      _canReply,
                                      _onReplySuccess);
                                },
                                    childCount: state
                                            .previousPages.replies.isEmpty
                                        ? 1
                                        : state.previousPages.replies.length),
                              ),
                              SliverList(
                                key: centerKey,
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    return _generatePageSliver(
                                        state,
                                        index,
                                        _onLastPage,
                                        _canReply,
                                        _onReplySuccess);
                                  },
                                  childCount: state.thread.replies.length,
                                ),
                              ),
                            ],
                          );
                        }
                      }(),
                floatingActionButton: _fabIsHidden || state is ThreadLoading
                    ? null
                    : () {
                        if (state is ThreadLoaded) {
                          if (state.thread.status == 'locked') {
                            return null;
                          } else {
                            return _buildFab(
                                context, state, _canReply, _onReplySuccess);
                          }
                        }
                      }(),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onReplySuccess(Reply reply) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('回覆發送成功!')));
    if (_onLastPage) {
      BlocProvider.of<ThreadBloc>(context)
          .add(AppendReplyToThreadEvent(reply: reply));
      SchedulerBinding.instance!.addPostFrameCallback((_) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
      });
    }
  }
}
