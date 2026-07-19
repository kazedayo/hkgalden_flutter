import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/cubit/thread_page_cubit.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/thread_reading_position.dart';
import 'package:hkgalden_flutter/models/ui_state_models/thread_page_state.dart';
import 'package:hkgalden_flutter/repository/thread_repository.dart';
import 'package:hkgalden_flutter/ui/common/compose_page/compose_page.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/error_page.dart';
import 'package:hkgalden_flutter/ui/common/progress_spinner.dart';
import 'package:hkgalden_flutter/ui/thread/comment_cell/comment_cell.dart';
import 'package:hkgalden_flutter/ui/thread/previous_page_pull_controller.dart';
import 'package:hkgalden_flutter/ui/thread/reply_position_anchor.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton_cell.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton_header.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_scroll_controller.dart';
import 'package:hkgalden_flutter/ui/thread/thread_restore_controller.dart';
import 'package:hkgalden_flutter/ui/thread/thread_scroll_physics.dart';
import 'package:hkgalden_flutter/utils/parsed_comment_html_cache.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';
import 'package:hkgalden_flutter/utils/thread_reading_position_store.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

part 'functions/thread_page_on_reply_success.dart';
part 'functions/thread_page_scroll_controller_listener.dart';
part 'widgets/thread_page_app_bar.dart';
part 'widgets/thread_page_fab.dart';
part 'widgets/thread_page_footer.dart';
part 'widgets/thread_page_header.dart';
part 'widgets/thread_page_previous_pull_indicator.dart';
part 'widgets/thread_page_previous_sliver.dart';
part 'widgets/thread_page_sliver.dart';
part 'widgets/thread_page_loaded_body.dart';

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

  int? _previousImageCacheMaxBytes;
  bool _didCaptureArgs = false;

  final GlobalKey _footerMeasureKey =
      GlobalKey(debugLabel: 'threadPageFooter');

  final ReplyAnchorRegistry _anchorRegistry = ReplyAnchorRegistry();
  int? _cachedLastFloor;
  ThreadBloc? _threadBloc;

  static const int _kThreadImageCacheMaxBytes = 96 << 20; // 96 MiB

  @override
  void initState() {
    super.initState();
    _scrollController = ThreadPageScrollController(keepScrollOffset: false);
    _threadPageCubit = ThreadPageCubit();
    _previousPull = PreviousPagePullController(vsync: this);
    _restore = ThreadRestoreController();
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

  double? _viewportTopY() {
    if (!_scrollController.hasClients) {
      return null;
    }
    final notificationContext =
        _scrollController.position.context.notificationContext;
    final box = notificationContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) {
      return null;
    }
    return box.localToGlobal(Offset.zero).dy;
  }

  bool _isAtScrollTrailingEdge() {
    if (!_scrollController.hasClients) {
      return false;
    }
    final position = _scrollController.position;
    if (!position.hasContentDimensions) {
      return false;
    }
    return position.pixels >= position.maxScrollExtent - 1.0;
  }

  void _syncTrailingEdgeLayout() {
    _restore.syncTrailingEdgeLayout(
      mounted: mounted,
      scrollController: _scrollController,
      footerBottomY: _footerBottomY,
      viewportTopY: _viewportTopY,
      safeBottom: MediaQuery.viewPaddingOf(context).bottom,
    );
  }

  void _updateCachedReadingFloor() {
    final topY = _viewportTopY();
    final atEnd = _isAtScrollTrailingEdge();

    int? viewportTopFloor;
    int? lastVisibleFloor;
    if (topY != null) {
      viewportTopFloor = _anchorRegistry.readingFloor(viewportTopY: topY);
      if (atEnd && _scrollController.hasClients) {
        final bottomY = topY +
            _scrollController.position.viewportDimension -
            MediaQuery.viewPaddingOf(context).bottom;
        lastVisibleFloor = _anchorRegistry.lastVisibleFloor(
          viewportTopY: topY,
          viewportBottomY: bottomY,
        );
      }
    }

    final state = _threadBloc?.state;
    final lastLoadedFloor = state is ThreadLoaded &&
            state.thread.replies.isNotEmpty
        ? state.thread.replies.last.floor
        : null;

    final floor = ThreadReadingPosition.resolveFloorForPersistence(
      viewportTopFloor: viewportTopFloor,
      lastVisibleFloor: lastVisibleFloor,
      lastLoadedFloor: lastLoadedFloor,
      atTrailingEdge: atEnd,
    );
    if (floor != null) {
      _cachedLastFloor = floor;
    }
  }

  void _persistReadingPosition() {
    final bloc = _threadBloc;
    if (bloc == null) {
      return;
    }
    final state = bloc.state;
    if (state is! ThreadLoaded) {
      return;
    }
    if (_anchorRegistry.hasEntries) {
      _updateCachedReadingFloor();
    } else if (_isAtScrollTrailingEdge() &&
        state.thread.replies.isNotEmpty) {
      final lastLoaded = state.thread.replies.last.floor;
      final resolved = ThreadReadingPosition.resolveFloorForPersistence(
        viewportTopFloor: _cachedLastFloor,
        lastVisibleFloor: null,
        lastLoadedFloor: lastLoaded,
        atTrailingEdge: true,
      );
      if (resolved != null) {
        _cachedLastFloor = resolved;
      }
    }
    final resolvedFloor = _cachedLastFloor ??
        (state.thread.replies.isNotEmpty
            ? state.thread.replies.last.floor
            : null);
    if (resolvedFloor == null) {
      return;
    }
    _cachedLastFloor = resolvedFloor;
    final page = ThreadReadingPosition.pageForFloor(resolvedFloor);
    ThreadReadingPositionStore.instance.save(
      state.thread.threadId,
      page: page,
      floor: resolvedFloor,
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
      _cachedLastFloor ??= _restore.seedCachedFloor(state);
    }
  }

  void _startRestoreSettle({required bool trailingEdge}) {
    _restore.startSettle(
      trailingEdge: trailingEdge,
      mounted: mounted,
      scrollController: _scrollController,
      footerBottomY: _footerBottomY,
      viewportTopY: _viewportTopY,
      safeBottom: () => MediaQuery.viewPaddingOf(context).bottom,
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
      _cachedLastFloor = arguments.floor;
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) {
          final ThreadBloc threadBloc = ThreadBloc(
              repository: RepositoryProvider.of<ThreadRepository>(context));
          _threadBloc = threadBloc;

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
            arguments,
            threadBloc,
            _scrollController,
            _threadPageCubit,
            _updateCachedReadingFloor,
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
            if (state is ThreadLoaded) {
              if ((state.thread.totalReplies.toDouble() / 50.0).ceil() >
                  state.endPage) {
                _threadPageCubit.setOnLastPage(false);
              } else {
                _threadPageCubit.setOnLastPage(true);
              }
              final session =
                  BlocProvider.of<SessionUserBloc>(context).state;
              ParsedCommentHtmlCache.instance.prewarm(
                [
                  ...state.thread.replies,
                  ...state.previousPages.replies,
                ],
                session,
              );
              _previousPull.onThreadLoaded(
                mounted: mounted,
                scrollController: _scrollController,
                hasPreviousReplies: state.previousPages.replies.isNotEmpty,
                schedulePostFrame: (fn) {
                  SchedulerBinding.instance.addPostFrameCallback((_) => fn());
                },
              );
              _resolveCenterAnchorIfNeeded(state);

              if (!_restore.didPinInitialCenter &&
                  state.previousPages.replies.isEmpty) {
                _restore.didPinInitialCenter = true;
                _startRestoreSettle(
                  trailingEdge: _restore.pendingRestoreToTrailingEdge,
                );
              }
            } else if (state is ThreadError) {
              _previousPull.clear(animate: true);
            }
          },
          buildWhen: (prev, state) =>
              state is! ThreadAppending && prev != state,
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
                  _resolveCenterAnchorIfNeeded(state);
                  return _buildLoadedThreadBody(
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
                    onReplySuccess: _onReplySuccess,
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
                  : _buildFab(
                      context,
                      _scrollController,
                      arguments,
                      _onReplySuccess,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
