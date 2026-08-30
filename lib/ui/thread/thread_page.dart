import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_cubit.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_cubit.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/ui/common/error_page.dart';
import 'package:hkgalden_flutter/ui/thread/previous_page_pull_controller.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_cubit_listener.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_on_reply_success.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_ui.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview.dart';
import 'package:hkgalden_flutter/ui/thread/widgets/thread_page_app_bar.dart';
import 'package:hkgalden_flutter/ui/thread/widgets/thread_page_fab.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';

class ThreadPage extends StatefulWidget {
  const ThreadPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ThreadPageState createState() => _ThreadPageState();
}

class _ThreadPageState extends State<ThreadPage> with WidgetsBindingObserver {
  late final ThreadPageUi _pageUi;
  late final PreviousPagePullController _previousPull;
  late final ThreadWebViewController _webView;

  bool _didCaptureArgs = false;
  double _safeBottom = 0;
  int? _restoreFloor;
  int? _threadId;

  @override
  void initState() {
    super.initState();
    _pageUi = ThreadPageUi();
    _previousPull = PreviousPagePullController();
    _webView = ThreadWebViewController();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    _pageUi.canReply.value =
        BlocProvider.of<SessionUserCubit>(context).state is SessionUserLoaded;
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
    _pageUi.dispose();
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

    return BlocProvider(
      create: (context) {
        final ThreadCubit threadCubit = ThreadCubit(
            api: RepositoryProvider.of<HKGaldenApi>(context));

        if (route != null &&
            route.animation != null &&
            route.animation!.status != AnimationStatus.completed) {
          void handler(AnimationStatus status) {
            if (status == AnimationStatus.completed) {
              route.animation!.removeStatusListener(handler);
              threadCubit.request(
                  threadId: arguments.threadId,
                  page: arguments.page,
                  isInitialLoad: true);
            }
          }

          route.animation!.addStatusListener(handler);
        } else {
          threadCubit.request(
              threadId: arguments.threadId,
              page: arguments.page,
              isInitialLoad: true);
        }

        return threadCubit;
      },
      child: BlocListener<SessionUserCubit, SessionUserState>(
        listenWhen: (prev, next) =>
            (prev is SessionUserLoaded) != (next is SessionUserLoaded),
        listener: (context, state) {
          _pageUi.canReply.value = state is SessionUserLoaded;
        },
        child: BlocConsumer<ThreadCubit, ThreadState>(
          listener: (context, state) {
            handleThreadPageCubitState(
              state: state,
              pageUi: _pageUi,
              previousPull: _previousPull,
            );
          },
          buildWhen: (prev, state) =>
              state is! ThreadAppending && prev != state,
          builder: (context, state) => Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: buildThreadPageAppBar(context, arguments, _pageUi),
            body: () {
              if (state is ThreadError) {
                return ErrorPage(
                  message: '無法載入主題',
                  onRetry: () => BlocProvider.of<ThreadCubit>(context).request(
                      threadId: arguments.threadId,
                      page: arguments.page,
                      isInitialLoad: true),
                );
              }
              return ListenableBuilder(
                listenable: _webView.contentReady,
                builder: (context, _) {
                  final loaded = state is ThreadLoaded;
                  return Stack(
                    children: [
                      if (loaded)
                        ThreadWebView(
                          key: ValueKey<int>(arguments.threadId),
                          controller: _webView,
                          restoreFloor: _restoreFloor,
                          previousPull: _previousPull,
                          pageUi: _pageUi,
                        ),
                      if (!_webView.contentReady.value)
                        Positioned.fill(
                          child: ColoredBox(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            child: const ThreadPageLoadingSkeleton(),
                          ),
                        ),
                    ],
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
                    _pageUi,
                  ),
          ),
        ),
      ),
    );
  }
}
