part of '../home_page.dart';

Theme _buildFrontLayer(
    BuildContext context,
    ThreadListBloc threadListBloc,
    ChannelBloc channelBloc,
    ThreadListState state,
    SessionUserBloc sessionUserBloc,
    ScrollController scrollController,
    Function(BuildContext, Thread) loadThread,
    Function(BuildContext, Thread) jumpToPage) {
  return Theme(
    data: Theme.of(context).copyWith(highlightColor: const Color(0xff373d3c)),
    child: Material(
      color: Theme.of(context).primaryColor,
      child: RefreshIndicator(
        color: AppTheme.activeColor,
        strokeWidth: 2.5,
        onRefresh: () {
          threadListBloc.add(RequestThreadListEvent(
              channelId: (channelBloc.state as ChannelLoaded).selectedChannelId,
              page: 1,
              isRefresh: true));
          return threadListBloc.stream
              .firstWhere((element) => element is! ThreadListLoading);
        },
        child: () {
          if (state is ThreadListLoading) {
            return ListLoadingSkeleton();
          } else if (state is ThreadListLoaded) {
            return ListView.builder(
              controller: scrollController,
              itemCount: state.threads.length + 1,
              itemBuilder: (context, index) {
                if (index == state.threads.length) {
                  return const ListLoadingSkeletonCell(enabled: false);
                } else {
                  return Visibility(
                    visible: () {
                      if (sessionUserBloc.state is SessionUserLoaded) {
                        return !(sessionUserBloc.state as SessionUserLoaded)
                            .sessionUser
                            .blockedUsers
                            .contains(
                                state.threads[index].replies[0].author.userId);
                      } else {
                        return true;
                      }
                    }(),
                    child: ThreadCell(
                      key: PageStorageKey(state.threads[index].threadId),
                      thread: state.threads[index],
                      onTap: () => loadThread(context, state.threads[index]),
                      onLongPress: () =>
                          jumpToPage(context, state.threads[index]),
                    ),
                  );
                }
              },
            );
          } else if (state is ThreadListError) {
            return ErrorPage(
              message: '無法載入主題列表',
              onRetry: () => BlocProvider.of<ThreadListBloc>(context).add(
                RequestThreadListEvent(
                  channelId:
                      (channelBloc.state as ChannelLoaded).selectedChannelId,
                  page: 1,
                  isRefresh: false,
                ),
              ),
            );
          }
          return const SizedBox();
        }(),
      ),
    ),
  );
}
