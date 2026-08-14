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
  double _safeBottom = 0;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _safeBottom = MediaQuery.viewPaddingOf(context).bottom;
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
    _persistReadingPosition(remeasure: false);
    final previous = _previousImageCacheMaxBytes;
    if (previous != null) {
      PaintingBinding.instance.imageCache.maximumSizeBytes = previous;
    }
    _previousPull.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _persistReadingPosition({bool remeasure = true}) {
    _reading.persist(safeBottom: _safeBottom, remeasure: remeasure);
  }

  void _persistReadingPositionFromScroll() {
    _persistReadingPosition();
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

  bool _onThreadScrollNotification(
    ScrollNotification notification,
    ThreadBloc threadBloc,
  ) {
    return _previousPull.onScrollNotification(
      notification,
      threadBloc,
      onScrollEndPersist: _persistReadingPositionFromScroll,
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
              onPinCenter: () => _restore.pinCenterIfNeeded(_scrollController),
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
                    previousPullExtent: _previousPull.extent,
                    previousPullLoading: _previousPull.loading,
                    centerStartIndex:
                        _restore.centerStartIndex(state.thread.replies),
                    onOverscrollIndicator: _previousPull.onOverscrollIndicator,
                    onScrollNotification: (notification) =>
                        _onThreadScrollNotification(
                      notification,
                      BlocProvider.of<ThreadBloc>(context),
                    ),
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
