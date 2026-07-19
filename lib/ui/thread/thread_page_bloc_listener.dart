import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:hkgalden_flutter/bloc/cubit/thread_page_cubit.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/ui/thread/previous_page_pull_controller.dart';
import 'package:hkgalden_flutter/ui/thread/thread_restore_controller.dart';
import 'package:hkgalden_flutter/utils/parsed_comment_html_cache.dart';

/// Side effects when [ThreadBloc] emits loaded / error states.
void handleThreadPageBlocState({
  required ThreadState state,
  required ThreadPageCubit pageCubit,
  required SessionUserState sessionState,
  required PreviousPagePullController previousPull,
  required ThreadRestoreController restore,
  required bool mounted,
  required ScrollController scrollController,
  required void Function(ThreadLoaded state) onResolveCenterAnchor,
  required void Function({required bool trailingEdge}) onStartRestoreSettle,
}) {
  if (state is ThreadLoaded) {
    final onLastPage =
        (state.thread.totalReplies.toDouble() / 50.0).ceil() <= state.endPage;
    pageCubit.setOnLastPage(onLastPage);

    ParsedCommentHtmlCache.instance.prewarm(
      [
        ...state.thread.replies,
        ...state.previousPages.replies,
      ],
      sessionState,
    );

    previousPull.onThreadLoaded(
      mounted: mounted,
      scrollController: scrollController,
      hasPreviousReplies: state.previousPages.replies.isNotEmpty,
      schedulePostFrame: (fn) {
        SchedulerBinding.instance.addPostFrameCallback((_) => fn());
      },
    );

    onResolveCenterAnchor(state);

    if (!restore.didPinInitialCenter && state.previousPages.replies.isEmpty) {
      restore.didPinInitialCenter = true;
      onStartRestoreSettle(
        trailingEdge: restore.pendingRestoreToTrailingEdge,
      );
    }
  } else if (state is ThreadError) {
    previousPull.clear(animate: true);
  }
}
