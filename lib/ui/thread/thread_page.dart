import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
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
import 'package:hkgalden_flutter/models/thread_reading_position.dart';
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

class ThreadPage extends StatefulWidget {
  const ThreadPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ThreadPageState createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late _ThreadScrollController _scrollController;
  late ThreadPageCubit _threadPageCubit;
  int? _previousImageCacheMaxBytes;

  /// Ensures the centered main window lands at offset 0 once after first load.
  bool _didPinInitialCenter = false;

  /// Floor from route args (last-seen restore request).
  int? _pendingRestoreFloor;
  bool _didCaptureArgs = false;

  /// Once resolved from the first loaded page: the floor that anchors the
  /// [CustomScrollView] center. Scroll offset 0 is the top of this reply —
  /// independent of image-driven height changes below or above.
  ///
  /// Null means center at the first reply of the main window (no mid-page restore).
  int? _centerAnchorFloor;
  bool _didResolveCenterAnchor = false;

  /// Built reply cells register here so we can resolve last-seen floor.
  final _ReplyAnchorRegistry _anchorRegistry = _ReplyAnchorRegistry();

  /// Last resolved reading floor (anchors unregister before parent dispose).
  int? _cachedLastFloor;

  /// Last known ThreadBloc for dispose-time persistence.
  ThreadBloc? _threadBloc;

  /// RefreshIndicator-style previous pull (manual extent, not parkable cells).
  bool _previousPullArmed = false;
  bool _previousPullLoading = false;
  bool _previousPullFingerDown = false;
  final ValueNotifier<double> _previousPullExtent = ValueNotifier<double>(0);

  /// Single snap-back controller (reused — do not create per gesture).
  late final AnimationController _previousPullSnapController;
  double _pullSnapBegin = 0;
  double _pullSnapEnd = 0;
  int _pullSnapGeneration = 0;

  /// Cap decoded image memory while on the thread page (reduces GC pressure).
  /// 96 MiB keeps more in-view comment images resident so returning from the
  /// full-screen viewer does not re-decode half the page.
  static const int _kThreadImageCacheMaxBytes = 96 << 20; // 96 MiB

  @override
  void initState() {
    // keepScrollOffset: false — avoid restoring a previous visit's offset
    // onto a new jump-in.
    // Maps status-bar "scroll to top" (animateTo/jumpTo 0) to the true
    // leading edge when content sits above the restore center anchor.
    _scrollController = _ThreadScrollController(keepScrollOffset: false);
    _threadPageCubit = ThreadPageCubit();
    _previousPullSnapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(_onPullSnapTick);
    final imageCache = PaintingBinding.instance.imageCache;
    _previousImageCacheMaxBytes = imageCache.maximumSizeBytes;
    if (imageCache.maximumSizeBytes > _kThreadImageCacheMaxBytes) {
      imageCache.maximumSizeBytes = _kThreadImageCacheMaxBytes;
    }
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Persist before process death / background so a kill mid-read is recoverable.
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
    _previousPullSnapController
      ..removeListener(_onPullSnapTick)
      ..dispose();
    _previousPullExtent.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Viewport top in global coordinates (body of the scroll view).
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

  /// Updates the in-memory last-seen floor from currently built anchors.
  ///
  /// Safe during dispose only if anchors still exist; otherwise leaves the
  /// last value written while the route was interactive.
  void _updateCachedReadingFloor() {
    final topY = _viewportTopY();
    if (topY == null) {
      return;
    }
    final floor = _anchorRegistry.readingFloor(viewportTopY: topY);
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
    // Prefer a live sample while the tree is still mounted with anchors.
    // On dispose, children unmount first and the registry is empty — use cache.
    if (_anchorRegistry.hasEntries) {
      _updateCachedReadingFloor();
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
    // Hive updates the in-memory map immediately; no need to await on dispose.
    ThreadReadingPositionStore.instance.save(
      state.thread.threadId,
      page: page,
      floor: resolvedFloor,
    );
  }

  /// Picks the center-sliver anchor floor from the first loaded page.
  ///
  /// Mid-page restore puts that floor at CustomScrollView center (offset 0)
  /// so we never estimate pixel offsets or wait for images to finish loading.
  void _resolveCenterAnchorIfNeeded(ThreadLoaded state) {
    if (_didResolveCenterAnchor) {
      return;
    }
    _didResolveCenterAnchor = true;
    final requested = _pendingRestoreFloor;
    final replies = state.thread.replies;
    if (requested == null || requested < 1 || replies.isEmpty) {
      return;
    }
    final idx = replies.indexWhere((r) => r.floor >= requested);
    if (idx > 0) {
      // Anchor at the first loaded floor at/after the saved position.
      _centerAnchorFloor = replies[idx].floor;
    } else if (idx < 0 && replies.length > 1) {
      // Saved floor is past this page's last reply — land on the last one.
      _centerAnchorFloor = replies.last.floor;
    }
    // idx == 0 → already at page start; leave _centerAnchorFloor null.

    // Seed last-seen so an immediate pop records the restore target.
    _cachedLastFloor ??= _centerAnchorFloor ?? replies.first.floor;
  }

  /// Index of the first main-window reply that belongs in the center sliver.
  int _centerStartIndex(List<Reply> replies) {
    final anchor = _centerAnchorFloor;
    if (anchor == null || replies.isEmpty) {
      return 0;
    }
    final idx = replies.indexWhere((r) => r.floor >= anchor);
    if (idx > 0) {
      return idx;
    }
    if (idx < 0 && replies.length > 1) {
      return replies.length - 1;
    }
    return 0;
  }

  void _onPullSnapTick() {
    final t =
        Curves.easeOutCubic.transform(_previousPullSnapController.value);
    _previousPullExtent.value =
        _pullSnapBegin + (_pullSnapEnd - _pullSnapBegin) * t;
  }

  void _stopPullSnapAnimation() {
    if (_previousPullSnapController.isAnimating) {
      // Invalidate in-flight whenComplete so a stopped run cannot clobber state.
      _pullSnapGeneration++;
      _previousPullSnapController.stop();
    }
  }

  void _clearPreviousPull({bool animate = false}) {
    _previousPullArmed = false;
    _previousPullLoading = false;
    _previousPullFingerDown = false;
    if (animate && _previousPullExtent.value > 0) {
      _animatePullExtentTo(0);
    } else {
      _stopPullSnapAnimation();
      if (_previousPullExtent.value != 0) {
        _previousPullExtent.value = 0;
      }
    }
  }

  void _setPullExtent(double value) {
    final next = value.clamp(0.0, _kPreviousPullIndicatorMaxExtent);
    if (next != _previousPullExtent.value) {
      _previousPullExtent.value = next;
    }
    // Arm = haptic only; never snap or commit here.
    if (next >= _kPreviousPullArmExtent) {
      if (!_previousPullArmed) {
        _previousPullArmed = true;
        HapticFeedback.mediumImpact();
      }
    } else if (next < _kPreviousPullDisarmExtent) {
      _previousPullArmed = false;
    }
  }

  void _animatePullExtentTo(double target) {
    _stopPullSnapAnimation();
    final begin = _previousPullExtent.value;
    if ((begin - target).abs() < 0.5) {
      _previousPullExtent.value = target;
      if (target == 0) {
        _previousPullArmed = false;
      }
      return;
    }
    _pullSnapBegin = begin;
    _pullSnapEnd = target;
    final generation = ++_pullSnapGeneration;
    _previousPullSnapController.forward(from: 0).whenComplete(() {
      if (!mounted || generation != _pullSnapGeneration) {
        return;
      }
      _previousPullExtent.value = target;
      if (target == 0) {
        _previousPullArmed = false;
      }
    });
  }

  /// Whether metrics are at the leading edge (top for a downward axis).
  ///
  /// Prefer [ScrollMetrics.extentBefore] like [RefreshIndicator] — works with
  /// a centered [CustomScrollView] where minScrollExtent may be negative.
  bool _isAtScrollTop(ScrollMetrics metrics) => metrics.extentBefore <= 0.5;

  /// Manual previous pull (same notification model as [RefreshIndicator]):
  /// - At top, [OverscrollNotification] grows pull (clamping does not move pixels)
  /// - Content is translated by pull extent; skeleton fills the gap
  /// - Cross arm threshold → haptic only (hold, no snap)
  /// - Finger up short → animate extent to 0
  /// - Finger up armed → load previous; hold indicator until data arrives
  bool _onThreadScrollNotification(
    ScrollNotification notification,
    ThreadBloc threadBloc,
  ) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }

    final state = threadBloc.state;

    // Reading-position tracking is independent of previous-page pull rules
    // (those early-out when currentPage <= 1 / ThreadAppending).
    if (state is ThreadLoaded || state is ThreadAppending) {
      if (notification is ScrollUpdateNotification ||
          notification is ScrollEndNotification) {
        _updateCachedReadingFloor();
      }
      if (notification is ScrollEndNotification && state is ThreadLoaded) {
        _persistReadingPosition();
      }
    }

    if (state is ThreadAppending) {
      // Keep loading indicator; ignore further pull input.
      return false;
    }
    if (state is! ThreadLoaded || state.currentPage <= 1) {
      if (_previousPullExtent.value > 0 || _previousPullArmed) {
        _clearPreviousPull();
      }
      return false;
    }

    if (_previousPullLoading) {
      return false;
    }

    final metrics = notification.metrics;
    if (!metrics.hasContentDimensions) {
      return false;
    }

    // AxisDirection.down: pulling past the top produces negative overscroll /
    // positive scrollDelta when releasing into content — same as RefreshIndicator.
    final axisDown = metrics.axisDirection == AxisDirection.down ||
        metrics.axisDirection == AxisDirection.right;

    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null && _isAtScrollTop(metrics)) {
        _previousPullFingerDown = true;
        _stopPullSnapAnimation();
      }
    } else if (notification is OverscrollNotification) {
      // Primary path under ClampingScrollPhysics: pixels stay put at the edge,
      // so ScrollUpdate often never fires — only overscroll does.
      if (notification.dragDetails == null) {
        return false;
      }
      if (!_previousPullFingerDown && !_isAtScrollTop(metrics)) {
        return false;
      }
      _previousPullFingerDown = true;
      _stopPullSnapAnimation();
      // RefreshIndicator: dragOffset -= overscroll (down axis).
      // Negative leading overscroll → pull extent increases.
      final delta = axisDown ? -notification.overscroll : notification.overscroll;
      if (delta != 0) {
        _setPullExtent(
          _previousPullExtent.value + delta * _kPreviousPullDragFactor,
        );
      }
    } else if (notification is ScrollUpdateNotification) {
      // Once pulled, scrollDelta reduces/increases extent as the user moves.
      // Also covers ballistic settle; only apply while a pull is active or at top
      // with an active finger drag.
      final scrollDelta = notification.scrollDelta;
      if (scrollDelta == null || scrollDelta == 0) {
        return false;
      }
      final pulling = _previousPullExtent.value > 0 ||
          (_previousPullFingerDown && _isAtScrollTop(metrics));
      if (!pulling) {
        return false;
      }
      if (notification.dragDetails != null) {
        _previousPullFingerDown = true;
      }
      // RefreshIndicator: dragOffset -= scrollDelta (down axis).
      final delta = axisDown ? -scrollDelta : scrollDelta;
      _setPullExtent(
        _previousPullExtent.value + delta * _kPreviousPullDragFactor,
      );
    } else if (notification is ScrollEndNotification) {
      if (_previousPullFingerDown || _previousPullExtent.value > 0) {
        _previousPullFingerDown = false;
        _handlePreviousPullRelease(threadBloc, state);
      }
    }

    return false;
  }

  /// Hide the Android/iOS overscroll glow while the user is pull-dragging.
  bool _onOverscrollIndicatorNotification(
    OverscrollIndicatorNotification notification,
  ) {
    if (notification.depth != 0 || !notification.leading) {
      return false;
    }
    if (_previousPullFingerDown || _previousPullExtent.value > 0) {
      notification.disallowIndicator();
      return true;
    }
    return false;
  }

  void _handlePreviousPullRelease(
    ThreadBloc threadBloc,
    ThreadLoaded state,
  ) {
    if (_previousPullLoading) {
      return;
    }
    if (_previousPullArmed && state.currentPage > 1) {
      _previousPullArmed = false;
      _previousPullLoading = true;
      // Keep full skeleton height until data arrives (do not shrink on commit).
      _stopPullSnapAnimation();
      _previousPullExtent.value = _kPreviousPullIndicatorMaxExtent;
      threadBloc.add(RequestThreadEvent(
        threadId: state.thread.threadId,
        page: state.currentPage - 1,
        isInitialLoad: false,
      ));
      return;
    }
    // Incomplete pull — ease the content back; no sudden clear.
    _previousPullArmed = false;
    if (_previousPullExtent.value > 0) {
      _animatePullExtentTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Key centerKey = ValueKey('second-sliver-list');
    final ThreadPageArguments arguments =
        ModalRoute.of(context)!.settings.arguments! as ThreadPageArguments;
    final route = ModalRoute.of(context);

    // Capture restore target once per route (floor within the requested page).
    if (!_didCaptureArgs) {
      _didCaptureArgs = true;
      _pendingRestoreFloor = arguments.floor;
      // Seed cache so an immediate pop still remembers the entry point.
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
              // Previous pull finished: replace the pull gap with real content
              // in place (no ease-back, no jump to the top of history).
              if (_previousPullLoading || _previousPullExtent.value > 0) {
                final wasLoading = _previousPullLoading;
                // Handoff the same gap we held while loading (full skeleton).
                final preserveGap = wasLoading
                    ? _kPreviousPullIndicatorMaxExtent
                    : _previousPullExtent.value;
                _previousPullLoading = false;
                _previousPullArmed = false;
                _previousPullFingerDown = false;
                _stopPullSnapAnimation();
                if (wasLoading && state.previousPages.replies.isNotEmpty) {
                  // Keep the translate until after layout, then convert the gap
                  // into a scroll offset into previousPages (above center) so
                  // the skeleton region becomes real posts without a visual jump.
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || !_scrollController.hasClients) {
                      return;
                    }
                    final position = _scrollController.position;
                    if (position.hasContentDimensions &&
                        position.minScrollExtent < 0) {
                      // Negative offset = into previous content; magnitude ≈ pull gap.
                      final target =
                          (-preserveGap).clamp(position.minScrollExtent, 0.0);
                      position.jumpTo(target);
                    }
                    // Drop pull chrome in the same frame as the offset handoff.
                    if (_previousPullExtent.value != 0) {
                      _previousPullExtent.value = 0;
                    }
                  });
                } else {
                  _previousPullExtent.value = 0;
                }
              }
              // Resolve mid-page center anchor before the first pin so the
              // builder can place the restored floor at scroll offset 0.
              _resolveCenterAnchorIfNeeded(state);

              // Pin to the center sliver on first content frame. With a mid-page
              // restore the center *is* the last-seen floor — no pixel jump.
              // holdCenterAtZero: status-bar remaps jumpTo(0) → minScrollExtent
              // once prefix/previous content exists; the pin must stay at center.
              if (!_didPinInitialCenter &&
                  state.previousPages.replies.isEmpty) {
                _didPinInitialCenter = true;
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  if (!mounted || !_scrollController.hasClients) {
                    return;
                  }
                  final position = _scrollController.position;
                  if (position.hasContentDimensions && position.pixels != 0) {
                    _scrollController.holdCenterAtZero = true;
                    try {
                      _scrollController.jumpTo(0);
                    } finally {
                      _scrollController.holdCenterAtZero = false;
                    }
                  }
                });
              }
            } else if (state is ThreadError) {
              _clearPreviousPull(animate: true);
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
                  // Ensure anchor is set even if the listener has not run yet.
                  _resolveCenterAnchorIfNeeded(state);

                  final allMain = state.thread.replies;
                  final centerStart = _centerStartIndex(allMain);
                  final prefixReplies = centerStart > 0
                      ? allMain.sublist(0, centerStart)
                      : const <Reply>[];
                  final centerReplies = centerStart > 0
                      ? allMain.sublist(centerStart)
                      : allMain;

                  // O(1) key → index maps for findChildIndexCallback.
                  // Must match ValueKey(_replyListKey(reply)); never use null keys.
                  //
                  // Slivers *above* the CustomScrollView center grow upward:
                  // builder index 0 is adjacent to the center. Chronological
                  // data must be reversed (same as previousPages).
                  final prefixKeyToBuilderIndex = <Object, int>{
                    for (var i = 0; i < prefixReplies.length; i++)
                      _replyListKey(prefixReplies[i]):
                          prefixReplies.length - i - 1,
                  };
                  final centerKeyToIndex = <Object, int>{
                    for (var i = 0; i < centerReplies.length; i++)
                      _replyListKey(centerReplies[i]): i,
                  };
                  // Previous sliver builder uses reversed indices:
                  // dataIndex → builderIndex = length - dataIndex - 1
                  final previousKeyToBuilderIndex = <Object, int>{
                    for (var i = 0; i < state.previousPages.replies.length; i++)
                      _replyListKey(state.previousPages.replies[i]):
                          state.previousPages.replies.length - i - 1,
                  };
                  final previousCount = state.previousPages.replies.length;
                  final prefixCount = prefixReplies.length;
                  return NotificationListener<OverscrollIndicatorNotification>(
                    onNotification: _onOverscrollIndicatorNotification,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) =>
                          _onThreadScrollNotification(
                        notification,
                        BlocProvider.of<ThreadBloc>(context),
                      ),
                      child: ListenableBuilder(
                        listenable: _previousPullExtent,
                        builder: (context, _) {
                          final pullExtent = _previousPullExtent.value;
                          // While loading we already parked extent at handoff size.
                          final displayExtent = pullExtent;
                          return Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              // Gap fill + skeleton above the translated list.
                              _PreviousPullIndicator(
                                extent: displayExtent,
                                loading: _previousPullLoading,
                              ),
                              // Content slides down with the pull (RefreshIndicator).
                              Transform.translate(
                                offset: Offset(0, displayExtent),
                                child: CustomScrollView(
                                  center: centerKey,
                                  controller: _scrollController,
                                  // Clamping: pull is driven by OverscrollNotification
                                  // (same as RefreshIndicator), not rubber-band physics.
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: ClampingScrollPhysics(),
                                  ),
                                  // Prefetch more off-screen so flings hit laid-out cells.
                                  // ignore: deprecated_member_use — ScrollCacheExtent is not exported via material.dart
                                  cacheExtent: 2000,
                                  slivers: <Widget>[
                                    // Above center: older pages, then same-page
                                    // replies before the restore floor.
                                    SliverList(
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          return _generatePreviousPageSliver(
                                              context,
                                              _scrollController,
                                              state,
                                              index,
                                              _onReplySuccess,
                                              _anchorRegistry);
                                        },
                                        findChildIndexCallback:
                                            previousCount == 0
                                                ? null
                                                : (Key key) {
                                                    if (key is ValueKey) {
                                                      return previousKeyToBuilderIndex[
                                                          key.value];
                                                    }
                                                    return null;
                                                  },
                                        childCount: previousCount,
                                      ),
                                    ),
                                    if (prefixCount > 0)
                                      SliverList(
                                        delegate: SliverChildBuilderDelegate(
                                          (context, index) {
                                            // Reverse like previousPages: index 0
                                            // is the reply just above the center.
                                            final dataIndex =
                                                prefixCount - index - 1;
                                            return _generatePageSliver(
                                              context,
                                              _scrollController,
                                              state,
                                              prefixReplies,
                                              dataIndex,
                                              _onReplySuccess,
                                              _anchorRegistry,
                                              isTrailingWindow: false,
                                            );
                                          },
                                          findChildIndexCallback: (Key key) {
                                            if (key is ValueKey) {
                                              return prefixKeyToBuilderIndex[
                                                  key.value];
                                            }
                                            return null;
                                          },
                                          childCount: prefixCount,
                                        ),
                                      ),
                                    // Center: restored floor (or page start) at
                                    // scroll offset 0 — stable under image loads.
                                    SliverList(
                                      key: centerKey,
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          return _generatePageSliver(
                                            context,
                                            _scrollController,
                                            state,
                                            centerReplies,
                                            index,
                                            _onReplySuccess,
                                            _anchorRegistry,
                                            isTrailingWindow: true,
                                          );
                                        },
                                        findChildIndexCallback: (Key key) {
                                          if (key is ValueKey) {
                                            return centerKeyToIndex[key.value];
                                          }
                                          return null;
                                        },
                                        childCount: centerReplies.length,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
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
              // Show FAB for the whole route when unlocked so the shared Hero
              // has a destination during the iOS push animation (load is
              // deferred until the transition finishes).
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

/// Scroll controller for the thread [CustomScrollView].
///
/// Mid-page restore places the last-seen floor at the scroll *center*
/// (offset 0). Content above that (same-page prefix + previous pages) lives at
/// negative offsets, so [minScrollExtent] is the true top.
///
/// Scaffold status-bar taps call [animateTo](0), which would land on the
/// restore floor. When content exists above the center, rewrite 0 →
/// [ScrollPosition.minScrollExtent] so "scroll to top" reaches the first
/// loaded reply. Intentional center pins set [holdCenterAtZero].
class _ThreadScrollController extends ScrollController {
  _ThreadScrollController({super.keepScrollOffset});

  /// When true, leave offset 0 alone (initial restore pin).
  bool holdCenterAtZero = false;

  double _resolveRequestedOffset(double offset) {
    if (offset != 0.0 || holdCenterAtZero || !hasClients) {
      return offset;
    }
    final position = this.position;
    if (!position.hasContentDimensions) {
      return offset;
    }
    final min = position.minScrollExtent;
    if (min < -0.5) {
      return min;
    }
    return offset;
  }

  @override
  Future<void> animateTo(
    double offset, {
    required Duration duration,
    required Curve curve,
  }) {
    return super.animateTo(
      _resolveRequestedOffset(offset),
      duration: duration,
      curve: curve,
    );
  }

  @override
  void jumpTo(double value) {
    super.jumpTo(_resolveRequestedOffset(value));
  }
}

/// Maps currently-built reply floors to their [BuildContext] for last-seen
/// position tracking while reading.
class _ReplyAnchorRegistry {
  final Map<int, BuildContext> _byFloor = {};

  bool get hasEntries => _byFloor.isNotEmpty;

  void register(int floor, BuildContext context) {
    _byFloor[floor] = context;
  }

  void unregister(int floor, BuildContext context) {
    if (identical(_byFloor[floor], context)) {
      _byFloor.remove(floor);
    }
  }

  /// Floor of the reply that best represents the reading position: the last
  /// reply whose top edge has reached (or passed) the viewport top.
  int? readingFloor({required double viewportTopY}) {
    int? bestFloor;
    var bestTop = double.negativeInfinity;
    int? nearestBelowFloor;
    var nearestBelowDist = double.infinity;

    for (final entry in _byFloor.entries) {
      final box = entry.value.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) {
        continue;
      }
      final top = box.localToGlobal(Offset.zero).dy;
      final bottom = top + box.size.height;
      // Skip fully above the viewport by a large margin only if we already
      // have a better candidate — keep-alives far above still compete via
      // "max top among tops past the edge", which is correct for reading pos.
      if (top <= viewportTopY + 24) {
        // Prefer the reply closest to the top edge from above (largest top).
        if (top >= bestTop) {
          bestTop = top;
          bestFloor = entry.key;
        }
      } else if (bottom > viewportTopY) {
        // Partially / fully below the top edge but still relevant.
        final dist = top - viewportTopY;
        if (dist < nearestBelowDist) {
          nearestBelowDist = dist;
          nearestBelowFloor = entry.key;
        }
      }
    }
    return bestFloor ?? nearestBelowFloor;
  }
}

/// Registers [floor] with [registry] while this subtree is mounted.
class _ReplyPositionAnchor extends StatefulWidget {
  final int floor;
  final _ReplyAnchorRegistry registry;
  final Widget child;

  const _ReplyPositionAnchor({
    required this.floor,
    required this.registry,
    required this.child,
  });

  @override
  State<_ReplyPositionAnchor> createState() => _ReplyPositionAnchorState();
}

class _ReplyPositionAnchorState extends State<_ReplyPositionAnchor> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.registry.register(widget.floor, context);
  }

  @override
  void didUpdateWidget(covariant _ReplyPositionAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.floor != widget.floor ||
        oldWidget.registry != widget.registry) {
      oldWidget.registry.unregister(oldWidget.floor, context);
      widget.registry.register(widget.floor, context);
    }
  }

  @override
  void dispose() {
    widget.registry.unregister(widget.floor, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
