import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/cubit/thread_page_cubit.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/repository/thread_repository.dart';
import 'package:hkgalden_flutter/ui/common/error_page.dart';
import 'package:hkgalden_flutter/ui/thread/previous_page_pull_controller.dart';
import 'package:hkgalden_flutter/ui/thread/reply_position_anchor.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_bloc_listener.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_on_reply_success.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_scroll_controller.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_scroll_listener.dart';
import 'package:hkgalden_flutter/ui/thread/thread_reading_position_tracker.dart';
import 'package:hkgalden_flutter/ui/thread/thread_restore_controller.dart';
import 'package:hkgalden_flutter/ui/thread/widgets/thread_page_app_bar.dart';
import 'package:hkgalden_flutter/ui/thread/widgets/thread_page_fab.dart';
import 'package:hkgalden_flutter/ui/thread/widgets/thread_page_loaded_body.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';

class ThreadPage extends StatefulWidget {
  const ThreadPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ThreadPageState createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final ThreadPageScrollController _scrollController;
  late final ThreadPageCubit _threadPageCubit;
  late final PreviousPagePullController _previousPull;
  late final ThreadRestoreController _restore;
  late final ThreadReadingPositionTracker _reading;

  int? _previousImageCacheMaxBytes;
  bool _didCaptureArgs = false;

  final GlobalKey _footerMeasureKey =
      GlobalKey(debugLabel: 'threadPageFooter');

  final ReplyAnchorRegistry _anchorRegistry = ReplyAnchorRegistry();

  static const int _kThreadImageCacheMaxBytes = 96 << 20; // 96 MiB

  @override
  void initState() {
    super.initState();
    _scrollController = ThreadPageScrollController(keepScrollOffset: false);
    _threadPageCubit = ThreadPageCubit();
    _previousPull = PreviousPagePullController(vsync: this);
    _restore = ThreadRestoreController();
    _reading = ThreadReadingPositionTracker(
      scrollController: _scrollController,
      anchorRegistry: _anchorRegistry,
    );
    final imageCache = PaintingBinding.instance.imageCache;
    _previousImageCacheMaxBytes = imageCache.maximumSizeBytes;
    if (imageCache.maximumSizeBytes > _kThreadImageCacheMaxBytes) {
      imageCache.maximumSizeBytes = _kThreadImageCacheMaxBytes;
    }
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _persistReadingPosition();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _persistReadingPosition();
    final previous = _previousImageCacheMaxBytes;
    if (previous != null) {
      PaintingBinding.instance.imageCache.maximumSizeBytes = previous;
    }
    _previousPull.dispose();
    _restore.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double? _footerBottomY() {
    final box = _footerMeasureKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) {
      return null;
    }
    return box.localToGlobal(Offset(0, box.size.height)).dy;
  }

  double get _safeBottom => MediaQuery.viewPaddingOf(context).bottom;

  void _persistReadingPosition() {
    _reading.persist(safeBottom: _safeBottom);
  }

  void _updateCachedReadingFloor() {
    _reading.updateCachedFloor(safeBottom: _safeBottom);
  }

  void _syncTrailingEdgeLayout() {
    _restore.syncTrailingEdgeLayout(
      mounted: mounted,
      scrollController: _scrollController,
      footerBottomY: _footerBottomY,
      viewportTopY: _reading.viewportTopY,
      safeBottom: _safeBottom,
    );
  }

  void _resolveCenterAnchorIfNeeded(ThreadLoaded state) {
    if (_restore.didResolveCenterAnchor) {
      return;
    }
    final hadRestoreRequest = _restore.pendingRestoreFloor != null &&
        _restore.pendingRestoreFloor! >= 1;
    _restore.resolveCenterAnchorIfNeeded(state);
    if (hadRestoreRequest) {
      _reading.cachedLastFloor ??= _restore.seedCachedFloor(state);
    }
  }

  void _startRestoreSettle({required bool trailingEdge}) {
    _restore.startSettle(
      trailingEdge: trailingEdge,
      mounted: mounted,
      scrollController: _scrollController,
      footerBottomY: _footerBottomY,
      viewportTopY: _reading.viewportTopY,
      safeBottom: () => _safeBottom,
    );
  }

  bool _onThreadScrollNotification(
    ScrollNotification notification,
    ThreadBloc threadBloc,
  ) {
    return _previousPull.onScrollNotification(
      notification,
      threadBloc,
      restoreSettling:
          _restore.settling || _restore.trailingEdgeLayoutActive,
      onUserDragDuringRestore: _restore.cancelSettle,
      onTrailingEdgeScroll: () {
        if (_restore.trailingEdgeLayoutActive) {
          _syncTrailingEdgeLayout();
        }
      },
      onScrollTick: _updateCachedReadingFloor,
      onScrollEndPersist: _persistReadingPosition,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThreadPageArguments arguments =
        ModalRoute.of(context)!.settings.arguments! as ThreadPageArguments;
    final route = ModalRoute.of(context);

    if (!_didCaptureArgs) {
      _didCaptureArgs = true;
      _restore.captureArgsFloor(arguments.floor);
      _reading.cachedLastFloor = arguments.floor;
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) {
          final ThreadBloc threadBloc = ThreadBloc(
              repository: RepositoryProvider.of<ThreadRepository>(context));
          _reading.threadBloc = threadBloc;

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

          attachThreadPageScrollListener(
            threadBloc: threadBloc,
            scrollController: _scrollController,
            cubit: _threadPageCubit,
            onScrollTick: _updateCachedReadingFloor,
          );
          return threadBloc;
        }),
        BlocProvider(create: (context) {
          _threadPageCubit.setCanReply(
              BlocProvider.of<SessionUserBloc>(context).state
                  is SessionUserLoaded);
          return _threadPageCubit;
        })
      ],
      child: BlocListener<SessionUserBloc, SessionUserState>(
        listenWhen: (prev, next) =>
            (prev is SessionUserLoaded) != (next is SessionUserLoaded),
        listener: (context, state) {
          _threadPageCubit.setCanReply(state is SessionUserLoaded);
        },
        child: BlocConsumer<ThreadBloc, ThreadState>(
          listener: (context, state) {
            handleThreadPageBlocState(
              state: state,
              pageCubit: _threadPageCubit,
              sessionState: BlocProvider.of<SessionUserBloc>(context).state,
              previousPull: _previousPull,
              restore: _restore,
              mounted: mounted,
              scrollController: _scrollController,
              onResolveCenterAnchor: _resolveCenterAnchorIfNeeded,
              onStartRestoreSettle: _startRestoreSettle,
            );
          },
          buildWhen: (prev, state) =>
              state is! ThreadAppending && prev != state,
          builder: (context, state) => PrimaryScrollController(
            controller: _scrollController,
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: buildThreadPageAppBar(context, arguments),
              body: () {
                if (state is ThreadLoading) {
                  return ThreadPageLoadingSkeleton();
                } else if (state is ThreadLoaded) {
                  _resolveCenterAnchorIfNeeded(state);
                  return buildLoadedThreadBody(
                    context: context,
                    state: state,
                    scrollController: _scrollController,
                    anchorRegistry: _anchorRegistry,
                    footerMeasureKey: _footerMeasureKey,
                    previousPullExtent: _previousPull.extent,
                    trailingTopPad: _restore.trailingTopPad,
                    restoreVisualReady: _restore.visualReady,
                    previousPullLoading: _previousPull.loading,
                    trailingEdgeLayoutActive:
                        _restore.trailingEdgeLayoutActive,
                    pendingRestoreToTrailingEdge:
                        _restore.pendingRestoreToTrailingEdge,
                    centerStartIndex:
                        _restore.centerStartIndex(state.thread.replies),
                    onOverscrollIndicator: _previousPull.onOverscrollIndicator,
                    onScrollNotification: (notification) =>
                        _onThreadScrollNotification(
                      notification,
                      BlocProvider.of<ThreadBloc>(context),
                    ),
                    onTrailingMetrics: _syncTrailingEdgeLayout,
                    onReplySuccess: onThreadReplySuccess,
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
              floatingActionButton: arguments.locked
                  ? null
                  : buildThreadPageFab(
                      context,
                      _scrollController,
                      arguments,
                      onThreadReplySuccess,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
