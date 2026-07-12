part of '../home_page.dart';

/// Distance from the end of the list at which the next page is requested.
/// Using a threshold (instead of exact max extent) starts the fetch slightly
/// earlier so the response is less likely to land mid-fling at the absolute end.
const double _kThreadListLoadMoreThreshold = 480;

void _initListener(BuildContext context, ScrollController scrollController) {
  scrollController.addListener(
    () {
      final position = scrollController.position;
      // Ignore if not scrollable yet or still far from the end.
      if (!position.hasContentDimensions) {
        return;
      }
      if (position.pixels <
          position.maxScrollExtent - _kThreadListLoadMoreThreshold) {
        return;
      }
      final state = BlocProvider.of<ThreadListBloc>(context).state;
      // ThreadListAppending extends ThreadListLoaded — skip both non-loaded
      // and in-flight append states so we do not request the same page twice.
      if (state is! ThreadListLoaded || state is ThreadListAppending) {
        return;
      }
      BlocProvider.of<ThreadListBloc>(context).add(
        RequestThreadListEvent(
            channelId: state.currentChannelId,
            page: state.currentPage + 1,
            isRefresh: false),
      );
    },
  );
}
