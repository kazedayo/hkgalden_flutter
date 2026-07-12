import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/cubit/thread_page_cubit.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/ui_state_models/thread_page_state.dart';
import 'package:hkgalden_flutter/repository/thread_repository.dart';
import 'package:hkgalden_flutter/ui/common/compose_page/compose_page.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/error_page.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';
import 'package:hkgalden_flutter/ui/thread/comment_cell/comment_cell.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton_cell.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton_header.dart';
import 'package:hkgalden_flutter/utils/parsed_comment_html_cache.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

part 'functions/thread_page_on_reply_success.dart';
part 'functions/thread_page_scroll_controller_listener.dart';
part 'widgets/thread_page_app_bar.dart';
part 'widgets/thread_page_fab.dart';
part 'widgets/thread_page_footer.dart';
part 'widgets/thread_page_header.dart';
part 'widgets/thread_page_previous_sliver.dart';
part 'widgets/thread_page_sliver.dart';

class ThreadPage extends StatefulWidget {
  const ThreadPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ThreadPageState createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> {
  late ScrollController _scrollController;
  late ThreadPageCubit _threadPageCubit;
  int? _previousImageCacheMaxBytes;

  /// Cap decoded image memory while on the thread page (reduces GC pressure).
  static const int _kThreadImageCacheMaxBytes = 48 << 20; // 48 MiB

  @override
  void initState() {
    _scrollController = ScrollController();
    _threadPageCubit = ThreadPageCubit();
    final imageCache = PaintingBinding.instance.imageCache;
    _previousImageCacheMaxBytes = imageCache.maximumSizeBytes;
    if (imageCache.maximumSizeBytes > _kThreadImageCacheMaxBytes) {
      imageCache.maximumSizeBytes = _kThreadImageCacheMaxBytes;
    }
    super.initState();
  }

  @override
  void dispose() {
    final previous = _previousImageCacheMaxBytes;
    if (previous != null) {
      PaintingBinding.instance.imageCache.maximumSizeBytes = previous;
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Key centerKey = ValueKey('second-sliver-list');
    final ThreadPageArguments arguments =
        ModalRoute.of(context)!.settings.arguments! as ThreadPageArguments;
    final route = ModalRoute.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) {
          final ThreadBloc threadBloc = ThreadBloc(
              repository: RepositoryProvider.of<ThreadRepository>(context));

          if (route != null &&
              route.animation != null &&
              route.animation!.status != AnimationStatus.completed) {
            void handler(AnimationStatus status) {
              if (status == AnimationStatus.completed) {
                route.animation!.removeStatusListener(handler);
                threadBloc.add(RequestThreadEvent(
                    threadId: arguments.threadId,
                    page: arguments.page,
                    isInitialLoad: true));
              }
            }

            route.animation!.addStatusListener(handler);
          } else {
            threadBloc.add(RequestThreadEvent(
                threadId: arguments.threadId,
                page: arguments.page,
                isInitialLoad: true));
          }

          _initListener(
              arguments, threadBloc, _scrollController, _threadPageCubit);
          return threadBloc;
        }),
        BlocProvider(create: (context) {
          // Seed from current session (listener only fires on later transitions).
          _threadPageCubit.setCanReply(
              BlocProvider.of<SessionUserBloc>(context).state
                  is SessionUserLoaded);
          return _threadPageCubit;
        })
      ],
      // Keep canReply in sync with session without side-effects in build.
      child: BlocListener<SessionUserBloc, SessionUserState>(
        listenWhen: (prev, next) =>
            (prev is SessionUserLoaded) != (next is SessionUserLoaded),
        listener: (context, state) {
          _threadPageCubit.setCanReply(state is SessionUserLoaded);
        },
        // Single Scaffold — no nested outer/inner pair.
        child: BlocConsumer<ThreadBloc, ThreadState>(
          listener: (context, state) {
            if (state is ThreadLoaded) {
              if ((state.thread.totalReplies.toDouble() / 50.0).ceil() >
                  state.endPage) {
                _threadPageCubit.setOnLastPage(false);
              } else {
                _threadPageCubit.setOnLastPage(true);
              }
              // Parse quote HTML when data arrives so cells hit cache mid-scroll.
              final session =
                  BlocProvider.of<SessionUserBloc>(context).state;
              ParsedCommentHtmlCache.instance.prewarm(
                [
                  ...state.thread.replies,
                  ...state.previousPages.replies,
                ],
                session,
              );
            }
          },
          buildWhen: (prev, state) =>
              state is! ThreadAppending && prev != state,
          // Register the thread scroll controller as primary so iOS status-bar
          // taps scroll this view to the top (Scaffold.handleStatusBarTap).
          builder: (context, state) => PrimaryScrollController(
            controller: _scrollController,
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: _buildAppBar(context, arguments),
              ),
              body: () {
                if (state is ThreadLoading) {
                  return ThreadPageLoadingSkeleton();
                } else if (state is ThreadLoaded) {
                  // O(1) key → index maps for findChildIndexCallback.
                  // Must match ValueKey(_replyListKey(reply)); never use null keys.
                  final replyKeyToIndex = <Object, int>{
                    for (var i = 0; i < state.thread.replies.length; i++)
                      _replyListKey(state.thread.replies[i]): i,
                  };
                  // Previous sliver builder uses reversed indices:
                  // dataIndex → builderIndex = length - dataIndex - 1
                  final previousKeyToBuilderIndex = <Object, int>{
                    for (var i = 0; i < state.previousPages.replies.length; i++)
                      _replyListKey(state.previousPages.replies[i]):
                          state.previousPages.replies.length - i - 1,
                  };
                  return CustomScrollView(
                    center: centerKey,
                    controller: _scrollController,
                    // Prefetch more off-screen so flings hit already-laid-out cells.
                    // ignore: deprecated_member_use — ScrollCacheExtent is not exported via material.dart
                    cacheExtent: 2000,
                    slivers: <Widget>[
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _generatePreviousPageSliver(
                                context,
                                _scrollController,
                                state,
                                index,
                                arguments.page,
                                _onReplySuccess);
                          },
                          findChildIndexCallback: (Key key) {
                            if (key is ValueKey) {
                              return previousKeyToBuilderIndex[key.value];
                            }
                            return null;
                          },
                          childCount: state.previousPages.replies.isEmpty
                              ? 1
                              : state.previousPages.replies.length,
                        ),
                      ),
                      SliverList(
                        key: centerKey,
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return _generatePageSliver(
                                context,
                                _scrollController,
                                state,
                                index,
                                _onReplySuccess);
                          },
                          findChildIndexCallback: (Key key) {
                            if (key is ValueKey) {
                              return replyKeyToIndex[key.value];
                            }
                            return null;
                          },
                          childCount: state.thread.replies.length,
                        ),
                      ),
                    ],
                  );
                } else if (state is ThreadError) {
                  return ErrorPage(
                    message: '無法載入主題',
                    onRetry: () => BlocProvider.of<ThreadBloc>(context).add(
                      RequestThreadEvent(
                          threadId: arguments.threadId,
                          page: arguments.page,
                          isInitialLoad: true),
                    ),
                  );
                }
                return null;
              }(),
              floatingActionButton: () {
                if (state is ThreadLoaded) {
                  if (state.thread.status == 'locked') {
                    return null;
                  } else {
                    return _buildFab(
                        context, _scrollController, state, _onReplySuccess);
                  }
                }
                return null;
              }(),
            ),
          ),
        ),
      ),
    );
  }
}
