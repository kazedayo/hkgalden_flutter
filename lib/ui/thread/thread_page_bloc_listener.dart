import 'package:hkgalden_flutter/bloc/cubit/thread_page_cubit.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/ui/thread/previous_page_pull_controller.dart';
import 'package:hkgalden_flutter/utils/parsed_comment_html_cache.dart';

/// Side effects when [ThreadBloc] emits loaded / error states.
void handleThreadPageBlocState({
  required ThreadState state,
  required ThreadPageCubit pageCubit,
  required SessionUserState sessionState,
  required PreviousPagePullController previousPull,
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
  } else if (state is ThreadError) {
    previousPull.clear(animate: true);
  }
}
