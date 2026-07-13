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

  bool _didPinInitialCenter = false;

  int? _pendingRestoreFloor;
  bool _didCaptureArgs = false;

  /// Floor at CustomScrollView center (offset 0); null = first main-window reply.
  int? _centerAnchorFloor;
  bool _didResolveCenterAnchor = false;

  final _ReplyAnchorRegistry _anchorRegistry = _ReplyAnchorRegistry();
  int? _cachedLastFloor;
  ThreadBloc? _threadBloc;

  bool _previousPullArmed = false;
  bool _previousPullLoading = false;
  bool _previousPullFingerDown = false;
  final ValueNotifier<double> _previousPullExtent = ValueNotifier<double>(0);

  late final AnimationController _previousPullSnapController;
  double _pullSnapBegin = 0;
  double _pullSnapEnd = 0;
  int _pullSnapGeneration = 0;

  static const int _kThreadImageCacheMaxBytes = 96 << 20; // 96 MiB

  @override
  void initState() {
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
    // On dispose anchors unmount first — fall back to cache.
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
    ThreadReadingPositionStore.instance.save(
      state.thread.threadId,
      page: page,
      floor: resolvedFloor,
    );
  }

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
      _centerAnchorFloor = replies[idx].floor;
    } else if (idx < 0 && replies.length > 1) {
      _centerAnchorFloor = replies.last.floor;
    }

    _cachedLastFloor ??= _centerAnchorFloor ?? replies.first.floor;
  }

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

  // extentBefore works with centered CustomScrollView (minScrollExtent may be negative).
  bool _isAtScrollTop(ScrollMetrics metrics) => metrics.extentBefore <= 0.5;

  bool _onThreadScrollNotification(
    ScrollNotification notification,
    ThreadBloc threadBloc,
  ) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }

    final state = threadBloc.state;

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

    final axisDown = metrics.axisDirection == AxisDirection.down ||
        metrics.axisDirection == AxisDirection.right;

    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null && _isAtScrollTop(metrics)) {
        _previousPullFingerDown = true;
        _stopPullSnapAnimation();
      }
    } else if (notification is OverscrollNotification) {
      // Clamping: overscroll is the primary pull signal (pixels don't move at edge).
      if (notification.dragDetails == null) {
        return false;
      }
      if (!_previousPullFingerDown && !_isAtScrollTop(metrics)) {
        return false;
      }
      _previousPullFingerDown = true;
      _stopPullSnapAnimation();
      final delta = axisDown ? -notification.overscroll : notification.overscroll;
      if (delta != 0) {
        _setPullExtent(
          _previousPullExtent.value + delta * _kPreviousPullDragFactor,
        );
      }
    } else if (notification is ScrollUpdateNotification) {
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
      _stopPullSnapAnimation();
      _previousPullExtent.value = _kPreviousPullIndicatorMaxExtent;
      threadBloc.add(RequestThreadEvent(
        threadId: state.thread.threadId,
        page: state.currentPage - 1,
        isInitialLoad: false,
      ));
      return;
    }
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

    if (!_didCaptureArgs) {
      _didCaptureArgs = true;
      _pendingRestoreFloor = arguments.floor;
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
              if (_previousPullLoading || _previousPullExtent.value > 0) {
                final wasLoading = _previousPullLoading;
                final preserveGap = wasLoading
                    ? _kPreviousPullIndicatorMaxExtent
                    : _previousPullExtent.value;
                _previousPullLoading = false;
                _previousPullArmed = false;
                _previousPullFingerDown = false;
                _stopPullSnapAnimation();
                if (wasLoading && state.previousPages.replies.isNotEmpty) {
                  // After layout: convert pull gap into scroll offset (no visual jump).
                  SchedulerBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || !_scrollController.hasClients) {
                      return;
                    }
                    final position = _scrollController.position;
                    if (position.hasContentDimensions &&
                        position.minScrollExtent < 0) {
                      final target =
                          (-preserveGap).clamp(position.minScrollExtent, 0.0);
                      position.jumpTo(target);
                    }
                    if (_previousPullExtent.value != 0) {
                      _previousPullExtent.value = 0;
                    }
                  });
                } else {
                  _previousPullExtent.value = 0;
                }
              }
              _resolveCenterAnchorIfNeeded(state);

              // Pin center at offset 0 once; holdCenterAtZero so status-bar remap
              // does not steal the initial restore pin.
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

                  final allMain = state.thread.replies;
                  final centerStart = _centerStartIndex(allMain);
                  final prefixReplies = centerStart > 0
                      ? allMain.sublist(0, centerStart)
                      : const <Reply>[];
                  final centerReplies = centerStart > 0
                      ? allMain.sublist(centerStart)
                      : allMain;

                  // Above-center slivers reverse chronological order (index 0 nearest center).
                  final prefixKeyToBuilderIndex = <Object, int>{
                    for (var i = 0; i < prefixReplies.length; i++)
                      _replyListKey(prefixReplies[i]):
                          prefixReplies.length - i - 1,
                  };
                  final centerKeyToIndex = <Object, int>{
                    for (var i = 0; i < centerReplies.length; i++)
                      _replyListKey(centerReplies[i]): i,
                  };
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
                          final displayExtent = pullExtent;
                          return Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              _PreviousPullIndicator(
                                extent: displayExtent,
                                loading: _previousPullLoading,
                              ),
                              Transform.translate(
                                offset: Offset(0, displayExtent),
                                child: CustomScrollView(
                                  center: centerKey,
                                  controller: _scrollController,
                                  physics: const AlwaysScrollableScrollPhysics(
                                    parent: ClampingScrollPhysics(),
                                  ),
                                  // ignore: deprecated_member_use — ScrollCacheExtent is not exported via material.dart
                                  cacheExtent: 2000,
                                  slivers: <Widget>[
                                    // Above center: previous pages + prefix before restore floor.
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
              // FAB present for Hero flight even while thread is still loading.
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

/// Remaps status-bar jumpTo/animateTo(0) → minScrollExtent when content sits
/// above the center restore floor. Set [holdCenterAtZero] during the initial pin.
class _ThreadScrollController extends ScrollController {
  _ThreadScrollController({super.keepScrollOffset});

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
      if (top <= viewportTopY + 24) {
        if (top >= bestTop) {
          bestTop = top;
          bestFloor = entry.key;
        }
      } else if (bottom > viewportTopY) {
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
