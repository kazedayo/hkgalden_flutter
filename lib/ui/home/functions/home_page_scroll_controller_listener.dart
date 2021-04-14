part of '../home_page.dart';

void _initListener(BuildContext context, ScrollController scrollController,
    Function(bool) callback) {
  scrollController.addListener(() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      BlocProvider.of<ThreadListBloc>(context).add(RequestThreadListEvent(
          channelId: (BlocProvider.of<ThreadListBloc>(context).state
                  as ThreadListLoaded)
              .currentChannelId,
          page: (BlocProvider.of<ThreadListBloc>(context).state
                      as ThreadListLoaded)
                  .currentPage +
              1,
          isRefresh: false));
    }
    if (scrollController.position.userScrollDirection ==
            ScrollDirection.forward ||
        scrollController.position.pixels == 0.0) {
      callback(false);
    } else if (scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      callback(true);
    }
  });
}
