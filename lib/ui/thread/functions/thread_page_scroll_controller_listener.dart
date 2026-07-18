part of '../thread_page.dart';

const double _kThreadPageLoadMoreThreshold = 480;

const double _kPreviousPullIndicatorMaxExtent =
    ThreadPageLoadingSkeletonCell.totalHeight; // 200

const double _kPreviousPullArmExtent = _kPreviousPullIndicatorMaxExtent * 0.80;

const double _kPreviousPullDisarmExtent = _kPreviousPullIndicatorMaxExtent * 0.70;

const double _kPreviousPullDragFactor = 0.85;

void _initListener(
  ThreadPageArguments arguments,
  ThreadBloc threadBloc,
  ScrollController scrollController,
  ThreadPageCubit cubit,
  void Function() onScrollTick,
) {
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

    onScrollTick();

    final state = threadBloc.state;
    if (state is ThreadLoaded) {
      final nearBottom = pixels >=
          position.maxScrollExtent - _kThreadPageLoadMoreThreshold;

      if (nearBottom && scrollingDown && !cubit.state.onLastPage) {
        threadBloc.add(RequestThreadEvent(
            threadId: state.thread.threadId,
            page: state.endPage + 1,
            isInitialLoad: false));
      }
    }
    final double newElevation = pixels > 0 ? 4.0 : 0.0;
    if (newElevation != cubit.state.elevation) {
      cubit.setElevation(newElevation);
    }
  });
}
