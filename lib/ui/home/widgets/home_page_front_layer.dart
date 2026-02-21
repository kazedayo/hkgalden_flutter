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
            final blockedUserIds = sessionUserBloc.state is SessionUserLoaded
                ? (sessionUserBloc.state as SessionUserLoaded)
                    .sessionUser
                    .blockedUsers
                    .toSet()
                : const <String>{};

            final threadIdToIndex = {
              for (var i = 0; i < state.threads.length; i++)
                state.threads[i].threadId: i
            };

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              controller: scrollController,
              cacheExtent: 500,
              itemCount: state.threads.length + 1,
              findChildIndexCallback: (Key key) {
                if (key is ValueKey<int>) {
                  return threadIdToIndex[key.value];
                }
                return null;
              },
              itemBuilder: (context, index) {
                if (index == state.threads.length) {
                  return const ListLoadingSkeletonCell(enabled: true);
                } else {
                  final thread = state.threads[index];

                  if (blockedUserIds
                      .contains(thread.replies[0].author.userId)) {
                    return const SizedBox.shrink();
                  }

                  return ThreadCell(
                    key: ValueKey(thread.threadId),
                    thread: thread,
                    onTap: () => loadThread(context, thread),
                    onLongPress: () => jumpToPage(context, thread),
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
