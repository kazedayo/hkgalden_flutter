part of '../home_page.dart';

void _initListener(BuildContext context, ScrollController scrollController) {
  scrollController.addListener(
    () {
      if (scrollController.position.pixels !=
          scrollController.position.maxScrollExtent) {
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
