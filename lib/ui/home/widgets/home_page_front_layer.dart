part of '../home_page.dart';

/// List/error/skeleton only — scoped under [ThreadListBloc] so chrome above
/// does not rebuild when the list appends or refreshes.
Widget _buildFrontLayer(
  BuildContext context,
  ThreadListBloc threadListBloc,
  ScrollController scrollController,
  Function(BuildContext, Thread) loadThread,
  Function(BuildContext, Thread) jumpToPage,
) {
  return Theme(
    data: Theme.of(context).copyWith(highlightColor: const Color(0xff373d3c)),
    child: Material(
      color: Theme.of(context).primaryColor,
      child: BlocBuilder<ThreadListBloc, ThreadListState>(
        // Skip pure append-in-flight transitions that share the same threads.
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
            // Nested SessionUser builder: refilter when block list changes
            // without depending on an unrelated thread-list emission.
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

    final visibleThreads = state.threads
        .where((thread) => thread.replies.isNotEmpty &&
            !blockedUserIds.contains(thread.replies[0].author.userId))
        .toList(growable: false);

    final threadIdToIndex = {
      for (var i = 0; i < visibleThreads.length; i++)
        visibleThreads[i].threadId: i
    };

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      controller: scrollController,
      cacheExtent: 500,
      itemCount: visibleThreads.length + 1,
      findChildIndexCallback: (Key key) {
        if (key is ValueKey<int>) {
          return threadIdToIndex[key.value];
        }
        return null;
      },
      itemBuilder: (context, index) {
        if (index == visibleThreads.length) {
          return const ListLoadingSkeletonCell(enabled: true);
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
