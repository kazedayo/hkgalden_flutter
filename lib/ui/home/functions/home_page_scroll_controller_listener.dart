part of '../home_page.dart';

/// Prefetch distance from list end for next-page load.
const double _kThreadListLoadMoreThreshold = 480;

void _initListener(BuildContext context, ScrollController scrollController) {
  scrollController.addListener(
    () {
      final position = scrollController.position;
      if (!position.hasContentDimensions) {
        return;
      }
      if (position.pixels <
          position.maxScrollExtent - _kThreadListLoadMoreThreshold) {
        return;
      }
      final state = BlocProvider.of<ThreadListBloc>(context).state;
      // ThreadListAppending extends ThreadListLoaded — skip in-flight appends.
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
