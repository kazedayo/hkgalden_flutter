part of '../thread_page.dart';

/// Distance from either end of the list at which the next/previous page is
/// requested. Using a threshold (instead of exact extent) starts the fetch
/// slightly earlier so the response is less likely to land mid-fling.
const double _kThreadPageLoadMoreThreshold = 480;

void _initListener(
  ThreadPageArguments arguments,
  ThreadBloc threadBloc,
  ScrollController scrollController,
  ThreadPageCubit cubit,
) {
  // Track scroll direction so a short list (both ends inside the threshold)
  // does not fire prev+next loads in a fighting order.
  double? lastPixels;

  scrollController.addListener(() {
    final position = scrollController.position;
    if (!position.hasContentDimensions) {
      return;
    }

    final pixels = position.pixels;
    final previousPixels = lastPixels;
    lastPixels = pixels;
    final scrollingDown =
        previousPixels == null || pixels > previousPixels + 0.5;
    final scrollingUp =
        previousPixels == null || pixels < previousPixels - 0.5;

    final state = threadBloc.state;
    // ThreadAppending is a separate state (does not extend ThreadLoaded), so
    // this also skips in-flight pagination and avoids casting crashes / spam.
    if (state is ThreadLoaded) {
      final nearBottom = pixels >=
          position.maxScrollExtent - _kThreadPageLoadMoreThreshold;
      final nearTop =
          pixels <= position.minScrollExtent + _kThreadPageLoadMoreThreshold;

      // Next page = after endPage (bottom of main window).
      // Previous page = before currentPage (top of main window).
      // Do NOT use currentPage+1 for next — after a downward append,
      // currentPage stays at the window start while endPage advances.
      if (nearBottom && scrollingDown && !cubit.state.onLastPage) {
        threadBloc.add(RequestThreadEvent(
            threadId: state.thread.threadId,
            page: state.endPage + 1,
            isInitialLoad: false));
      } else if (nearTop && scrollingUp && state.currentPage > 1) {
        threadBloc.add(RequestThreadEvent(
            threadId: state.thread.threadId,
            page: state.currentPage - 1,
            isInitialLoad: false));
      }
    }
    final double newElevation =
        pixels > position.minScrollExtent ? 4.0 : 0.0;
    if (newElevation != cubit.state.elevation) {
      cubit.setElevation(newElevation);
    }
  });
}
