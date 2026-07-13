part of '../thread_page.dart';

/// Prefetch distance for next page (bottom). Starts the fetch slightly early
/// so the response is less likely to land mid-fling.
const double _kThreadPageLoadMoreThreshold = 480;

/// Max pull / skeleton reveal height — match [ThreadPageLoadingSkeletonCell.totalHeight].
/// Also used as the loading hold height and post-load scroll handoff so the
/// gap never shrinks mid-gesture.
const double _kPreviousPullIndicatorMaxExtent =
    ThreadPageLoadingSkeletonCell.totalHeight; // 200

/// Pull distance required to arm previous-page load (≥ 80% of max extent).
const double _kPreviousPullArmExtent = _kPreviousPullIndicatorMaxExtent * 0.80;

/// Disarm hysteresis while the finger is still down (~70% of max).
const double _kPreviousPullDisarmExtent = _kPreviousPullIndicatorMaxExtent * 0.70;

/// Slight resistance so the pull feels weighted (1.0 = 1:1 with overscroll).
const double _kPreviousPullDragFactor = 0.85;

void _initListener(
  ThreadPageArguments arguments,
  ThreadBloc threadBloc,
  ScrollController scrollController,
  ThreadPageCubit cubit,
  void Function() onScrollTick,
) {
  // Track scroll direction so a short list (both ends inside a threshold)
  // does not fire next loads without intent. Previous page uses manual pull
  // in [_ThreadPageState._onThreadScrollNotification].
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

    // Keep last-seen floor in sync on every scroll tick (not only via
    // NotificationListener, which early-outs for previous-pull / page 1).
    onScrollTick();

    final state = threadBloc.state;
    if (state is ThreadLoaded) {
      final nearBottom = pixels >=
          position.maxScrollExtent - _kThreadPageLoadMoreThreshold;

      // Next page only — previous is pull-to-load.
      if (nearBottom && scrollingDown && !cubit.state.onLastPage) {
        threadBloc.add(RequestThreadEvent(
            threadId: state.thread.threadId,
            page: state.endPage + 1,
            isInitialLoad: false));
      }
    }
    // Elevation relative to the main window start (center at 0).
    final double newElevation = pixels > 0 ? 4.0 : 0.0;
    if (newElevation != cubit.state.elevation) {
      cubit.setElevation(newElevation);
    }
  });
}
