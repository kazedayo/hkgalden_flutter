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

  @override
  void initState() {
    _scrollController = ScrollController();
    _threadPageCubit = ThreadPageCubit();
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
    _threadPageCubit.setCanReply(sessionUserBloc.state is SessionUserLoaded);
    return RepositoryProvider(
      create: (context) => ThreadRepository(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) {
            final ThreadBloc threadBloc = ThreadBloc(
                repository: RepositoryProvider.of<ThreadRepository>(context));

            final route = ModalRoute.of(context);
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
          BlocProvider(create: (context) => _threadPageCubit)
        ],
        child: Scaffold(
          body: BlocConsumer<ThreadBloc, ThreadState>(
            listener: (context, state) {
              if (state is ThreadLoaded) {
                if ((state.thread.totalReplies.toDouble() / 50.0).ceil() >
                    state.endPage) {
                  _threadPageCubit.setOnLastPage(false);
                } else {
                  _threadPageCubit.setOnLastPage(true);
                }
              }
            },
            buildWhen: (prev, state) =>
                state is! ThreadAppending && prev != state,
            builder: (context, state) => Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: _buildAppBar(context, arguments),
              ),
              body: () {
                if (state is ThreadLoading) {
                  return ThreadPageLoadingSkeleton();
                } else if (state is ThreadLoaded) {
                  return CustomScrollView(
                    center: centerKey,
                    controller: _scrollController,
                    slivers: <Widget>[
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _generatePreviousPageSliver(
                              context,
                              _scrollController,
                              state,
                              index,
                              arguments.page,
                              _onReplySuccess);
                        },
                            childCount: state.previousPages.replies.isEmpty
                                ? 1
                                : state.previousPages.replies.length),
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
              }(),
            ),
          ),
        ),
      ),
    );
  }
}
