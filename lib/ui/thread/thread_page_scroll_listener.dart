import 'package:flutter/widgets.dart';
import 'package:hkgalden_flutter/bloc/cubit/thread_page_cubit.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';

const double kThreadPageLoadMoreThreshold = 480;

/// Attach load-more + app-bar elevation side effects to [scrollController].
void attachThreadPageScrollListener({
  required ThreadBloc threadBloc,
  required ScrollController scrollController,
  required ThreadPageCubit cubit,
}) {
  double? lastPixels;

  scrollController.addListener(() {
    final position = scrollController.position;
    if (!position.hasContentDimensions) {
      return;
    }

    final pixels = position.pixels;
    final previousPixels = lastPixels;
    lastPixels = pixels;

    final hasDelta = previousPixels != null;
    final scrollingDown = hasDelta && pixels > previousPixels + 0.5;

    final state = threadBloc.state;
    if (state is ThreadLoaded) {
      final nearBottom =
          pixels >= position.maxScrollExtent - kThreadPageLoadMoreThreshold;

      if (nearBottom && scrollingDown && !cubit.state.onLastPage) {
        threadBloc.add(RequestThreadEvent(
          threadId: state.thread.threadId,
          page: state.endPage + 1,
          isInitialLoad: false,
        ));
      }
    }
    final double newElevation = pixels > 0 ? 4.0 : 0.0;
    if (newElevation != cubit.state.elevation) {
      cubit.setElevation(newElevation);
    }
  });
}
