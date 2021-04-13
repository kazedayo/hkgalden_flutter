part of '../home_page.dart';

Theme _buildFrontLayer(
    BuildContext context,
    ThreadListBloc threadListBloc,
    ChannelBloc channelBloc,
    ThreadListState state,
    SessionUserBloc sessionUserBloc,
    ScrollController scrollController,
    Function(Thread) loadThread,
    Function(Thread) jumpToPage) {
  return Theme(
    data: Theme.of(context).copyWith(highlightColor: const Color(0xff373d3c)),
    child: Material(
      color: Theme.of(context).primaryColor,
      child: RefreshIndicator(
          backgroundColor: Colors.white,
          strokeWidth: 2.5,
          onRefresh: () {
            threadListBloc.add(RequestThreadListEvent(
                channelId:
                    (channelBloc.state as ChannelLoaded).selectedChannelId,
                page: 1,
                isRefresh: true));
            return threadListBloc.stream
                .firstWhere((element) => element is! ThreadListLoading);
          },
          child: state is ThreadListLoading
              ? ListLoadingSkeleton()
              : () {
                  if (state is ThreadListLoaded) {
                    return ListView.builder(
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: false,
                      controller: scrollController,
                      itemCount: state.threads.length + 1,
                      itemBuilder: (context, index) {
                        if (index == state.threads.length) {
                          return ListLoadingSkeletonCell();
                        } else {
                          return Visibility(
                            visible: () {
                              if (sessionUserBloc.state is SessionUserLoaded) {
                                return !(sessionUserBloc.state
                                        as SessionUserLoaded)
                                    .sessionUser
                                    .blockedUsers
                                    .contains(state.threads[index].replies[0]
                                        .author.userId);
                              } else {
                                return true;
                              }
                            }(),
                            child: ThreadCell(
                              key: ValueKey(state.threads[index].threadId),
                              thread: state.threads[index],
                              onTap: () => loadThread(state.threads[index]),
                              onLongPress: () =>
                                  jumpToPage(state.threads[index]),
                            ),
                          );
                        }
                      },
                    );
                  }
                  return const SizedBox();
                }()),
    ),
  );
}
