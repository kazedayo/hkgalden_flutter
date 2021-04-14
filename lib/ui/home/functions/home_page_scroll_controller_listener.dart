part of '../home_page.dart';

void _initListener(BuildContext context, ScrollController scrollController) {
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
  });
}
