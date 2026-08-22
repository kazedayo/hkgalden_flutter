import 'package:hkgalden_flutter/bloc/session_user/session_user_cubit.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_cubit.dart';
import 'package:hkgalden_flutter/ui/thread/previous_page_pull_controller.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_ui.dart';
import 'package:hkgalden_flutter/utils/parsed_comment_html_cache.dart';

/// Side effects when [ThreadCubit] emits loaded / error states.
void handleThreadPageCubitState({
  required ThreadState state,
  required ThreadPageUi pageUi,
  required SessionUserState sessionState,
  required PreviousPagePullController previousPull,
}) {
  if (state is ThreadLoaded) {
    final onLastPage =
        (state.thread.totalReplies.toDouble() / 50.0).ceil() <= state.endPage;
    pageUi.onLastPage.value = onLastPage;

    ParsedCommentHtmlCache.instance.prewarm(
      [
        ...state.thread.replies,
        ...state.previousPages.replies,
      ],
      sessionState,
    );
  } else if (state is ThreadError) {
    previousPull.clear();
  }
}
