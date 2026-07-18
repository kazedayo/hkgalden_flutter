part of '../home_page.dart';

/// List body under [ThreadListBloc] (chrome stays outside).
Widget _buildFrontLayer(
  BuildContext context,
  ThreadListBloc threadListBloc,
  ScrollController scrollController,
  Function(BuildContext, Thread) loadThread,
  Function(BuildContext, Thread) jumpToPage,
) {
  return Material(
    color: Theme.of(context).primaryColor,
    child: BlocBuilder<ThreadListBloc, ThreadListState>(
      buildWhen: (prev, state) {
        if (state is ThreadListAppending) {
          return false;
        }
        return prev != state;
      },
      builder: (context, state) {
        final channelBloc = BlocProvider.of<ChannelBloc>(context);

        return RefreshIndicator(
          color: AppTheme.activeColor,
          strokeWidth: 2.5,
          onRefresh: () {
            final channelState = channelBloc.state;
            if (channelState is! ChannelLoaded) {
              return Future<void>.value();
            }
            threadListBloc.add(RequestThreadListEvent(
                channelId: channelState.selectedChannelId,
                page: 1,
                isRefresh: true));
            return threadListBloc.stream
                .firstWhere((element) => element is! ThreadListLoading);
          },
          child: BlocBuilder<SessionUserBloc, SessionUserState>(
            buildWhen: (prev, next) =>
                !_sameBlockedUsers(prev, next) ||
                (prev is SessionUserLoaded) != (next is SessionUserLoaded),
            builder: (context, sessionState) {
              return _frontLayerBody(
                context,
                state,
                sessionState,
                channelBloc,
                scrollController,
                loadThread,
                jumpToPage,
              );
            },
          ),
        );
      },
    ),
  );
}

bool _sameBlockedUsers(SessionUserState a, SessionUserState b) {
  List<String> ids(SessionUserState s) => s is SessionUserLoaded
      ? List<String>.from(s.sessionUser.blockedUsers)
      : const <String>[];
  final left = ids(a)..sort();
  final right = ids(b)..sort();
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

List<Thread> _filterVisibleThreads(
  List<Thread> threads,
  Set<String> blockedUserIds,
) {
  if (blockedUserIds.isEmpty) {
    return [
      for (final thread in threads)
        if (thread.replies.isNotEmpty) thread,
    ];
  }
  return [
    for (final thread in threads)
      if (thread.replies.isNotEmpty &&
          !blockedUserIds.contains(thread.originalPost.author.userId))
        thread,
  ];
}

Widget _frontLayerBody(
  BuildContext context,
  ThreadListState state,
  SessionUserState sessionState,
  ChannelBloc channelBloc,
  ScrollController scrollController,
  Function(BuildContext, Thread) loadThread,
  Function(BuildContext, Thread) jumpToPage,
) {
  if (state is ThreadListLoading) {
    return ListLoadingSkeleton();
  }
  if (state is ThreadListLoaded) {
    final blockedUserIds = sessionState is SessionUserLoaded
        ? sessionState.sessionUser.blockedUsers.toSet()
        : const <String>{};

    final visibleThreads =
        _filterVisibleThreads(state.threads, blockedUserIds);

    final threadIdToIndex = <int, int>{
      for (var i = 0; i < visibleThreads.length; i++)
        visibleThreads[i].threadId: i,
    };

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      controller: scrollController,
      // ignore: deprecated_member_use — ScrollCacheExtent is not exported via material.dart
      cacheExtent: 900,
      itemCount: visibleThreads.length + 1,
      findChildIndexCallback: (Key key) {
        if (key is ValueKey<int>) {
          return threadIdToIndex[key.value];
        }
        return null;
      },
      itemBuilder: (context, index) {
        if (index == visibleThreads.length) {
          return BlocBuilder<ThreadListBloc, ThreadListState>(
            buildWhen: (prev, next) =>
                (prev is ThreadListAppending) != (next is ThreadListAppending),
            builder: (context, listState) {
              if (listState is ThreadListAppending) {
                return const _ThreadListLoadMoreFooter();
              }
              return const SizedBox.shrink();
            },
          );
        }
        final thread = visibleThreads[index];
        return ThreadCell(
          key: ValueKey(thread.threadId),
          thread: thread,
          onTap: () => loadThread(context, thread),
          onLongPress: () => jumpToPage(context, thread),
        );
      },
    );
  }
  if (state is ThreadListError) {
    final channelState = channelBloc.state;
    return ErrorPage(
      message: '無法載入主題列表',
      onRetry: () {
        if (channelState is! ChannelLoaded) {
          return;
        }
        BlocProvider.of<ThreadListBloc>(context).add(
          RequestThreadListEvent(
            channelId: channelState.selectedChannelId,
            page: 1,
            isRefresh: false,
          ),
        );
      },
    );
  }
  return const SizedBox();
}

class _ThreadListLoadMoreFooter extends StatelessWidget {
  const _ThreadListLoadMoreFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.activeColor,
          ),
        ),
      ),
    );
  }
}
