import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/cubit/thread_page_cubit.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/repository/thread_repository.dart';
import 'package:hkgalden_flutter/ui/common/error_page.dart';
import 'package:hkgalden_flutter/ui/thread/previous_page_pull_controller.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_bloc_listener.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_on_reply_success.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview.dart';
import 'package:hkgalden_flutter/ui/thread/widgets/thread_page_app_bar.dart';
import 'package:hkgalden_flutter/ui/thread/widgets/thread_page_fab.dart';
import 'package:hkgalden_flutter/ui/thread/widgets/thread_page_previous_pull_indicator.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';

class ThreadPage extends StatefulWidget {
  const ThreadPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ThreadPageState createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final ThreadPageCubit _threadPageCubit;
  late final PreviousPagePullController _previousPull;
  late final ThreadWebViewController _webView;

  bool _didCaptureArgs = false;
  double _safeBottom = 0;
  int? _restoreFloor;
  int? _threadId;
  final GlobalKey _skeletonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _threadPageCubit = ThreadPageCubit();
    _previousPull = PreviousPagePullController(vsync: this);
    _webView = ThreadWebViewController();
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
    _previousPull.dispose();
    _webView.dispose();
    super.dispose();
  }

  void _persistReadingPosition({bool remeasure = true}) {
    _webView.threadId ??= _threadId;
    _webView.persist(safeBottom: _safeBottom, remeasure: remeasure);
  }

  @override
  Widget build(BuildContext context) {
    final ThreadPageArguments arguments =
        ModalRoute.of(context)!.settings.arguments! as ThreadPageArguments;
    final route = ModalRoute.of(context);

    if (!_didCaptureArgs) {
      _didCaptureArgs = true;
      _restoreFloor = arguments.floor;
      _threadId = arguments.threadId;
      _webView.threadId = arguments.threadId;
      _webView.cachedLastFloor = arguments.floor;
    }

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
            );
          },
          buildWhen: (prev, state) =>
              state is! ThreadAppending && prev != state,
          builder: (context, state) => Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: buildThreadPageAppBar(context, arguments),
            body: () {
              if (state is ThreadError) {
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
              return ListenableBuilder(
                listenable: _webView.contentReady,
                builder: (context, _) {
                  return ListenableBuilder(
                    listenable: _previousPull.extent,
                    builder: (context, _) {
                      final loaded = state is ThreadLoaded;
                      return Stack(
                        children: [
                          if (loaded)
                            Transform.translate(
                              offset: Offset(0, _previousPull.extent.value),
                              child: ThreadWebView(
                                key: ValueKey<int>(arguments.threadId),
                                controller: _webView,
                                restoreFloor: _restoreFloor,
                                previousPull: _previousPull,
                              ),
                            ),
                          if (!_webView.contentReady.value)
                            Positioned.fill(
                              key: _skeletonKey,
                              child: ColoredBox(
                                color: Theme.of(context)
                                    .scaffoldBackgroundColor,
                                child: const ThreadPageLoadingSkeleton(),
                              ),
                            ),
                          if (loaded)
                            ThreadPagePreviousPullIndicator(
                              extent: _previousPull.extent.value,
                              loading: _previousPull.loading,
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            }(),
            floatingActionButton: arguments.locked
                ? null
                : buildThreadPageFab(
                    context,
                    _webView,
                    arguments,
                    onThreadReplySuccess,
                  ),
          ),
        ),
      ),
    );
  }
}
