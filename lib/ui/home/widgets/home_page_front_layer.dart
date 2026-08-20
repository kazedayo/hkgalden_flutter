part of '../home_page.dart';

/// List body under [ThreadListCubit] (chrome stays outside).
Widget _buildFrontLayer(
  BuildContext context,
  ThreadListCubit threadListBloc,
  ScrollController scrollController,
  Function(BuildContext, Thread) loadThread,
  Function(BuildContext, Thread) jumpToPage,
) {
  return Material(
    color: Theme.of(context).primaryColor,
    child: BlocBuilder<ThreadListCubit, ThreadListState>(
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
            threadListBloc.load(
                channelId: channelState.selectedChannelId,
                page: 1,
                isRefresh: true);
            return threadListBloc.stream.firstWhere((element) =>
                element is ThreadListError ||
                (element is ThreadListLoaded &&
                    element is! ThreadListAppending));
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

    return _ThreadListView(
      threads: visibleThreads,
      scrollController: scrollController,
      loadThread: loadThread,
      jumpToPage: jumpToPage,
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
        BlocProvider.of<ThreadListCubit>(context).load(
          channelId: channelState.selectedChannelId,
          page: 1,
        );
      },
    );
  }
  return const SizedBox();
}

class _ThreadListView extends StatefulWidget {
  final List<Thread> threads;
  final ScrollController scrollController;
  final void Function(BuildContext, Thread) loadThread;
  final void Function(BuildContext, Thread) jumpToPage;

  const _ThreadListView({
    required this.threads,
    required this.scrollController,
    required this.loadThread,
    required this.jumpToPage,
  });

  @override
  State<_ThreadListView> createState() => _ThreadListViewState();
}

class _ThreadListViewState extends State<_ThreadListView> {
  static const double _loadMoreFooterHeight = 54;
  final Map<int, double> _heights = <int, double>{};
  double? _measuredWidth;
  TextScaler? _measuredScaler;

  void _measureMissing(BuildContext context, List<Thread> threads) {
    final width = MediaQuery.sizeOf(context).width;
    final scaler = MediaQuery.textScalerOf(context);
    if (_measuredWidth != width || _measuredScaler != scaler) {
      _heights.clear();
      _measuredWidth = width;
      _measuredScaler = scaler;
    }
    if (threads.every((thread) => _heights.containsKey(thread.threadId))) {
      return;
    }
    for (final thread in threads) {
      if (_heights.containsKey(thread.threadId)) {
        continue;
      }
      _heights[thread.threadId] = ThreadCell.measureHeight(
        context: context,
        thread: thread,
        maxWidth: width,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final threads = widget.threads;
    _measureMissing(context, threads);
    final threadIdToIndex = <int, int>{
      for (var i = 0; i < threads.length; i++) threads[i].threadId: i,
    };
    final threadListBloc = BlocProvider.of<ThreadListCubit>(context);

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      controller: widget.scrollController,
      // ignore: deprecated_member_use — ScrollCacheExtent is not exported via material.dart
      cacheExtent: 250,
      addAutomaticKeepAlives: false,
      itemCount: threads.length + 1,
      itemExtentBuilder: (index, _) {
        if (index == threads.length) {
          return threadListBloc.state is ThreadListAppending
              ? _loadMoreFooterHeight
              : 0;
        }
        if (index < 0 || index >= threads.length) {
          return null;
        }
        return _heights[threads[index].threadId];
      },
      findChildIndexCallback: (Key key) {
        if (key is ValueKey<int>) {
          return threadIdToIndex[key.value];
        }
        return null;
      },
      itemBuilder: (context, index) {
        if (index == threads.length) {
          return BlocBuilder<ThreadListCubit, ThreadListState>(
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
        final thread = threads[index];
        return ThreadCell(
          key: ValueKey(thread.threadId),
          thread: thread,
          onTap: () => widget.loadThread(context, thread),
          onLongPress: () => widget.jumpToPage(context, thread),
        );
      },
    );
  }
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
