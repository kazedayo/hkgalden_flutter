part of '../thread_page.dart';

/// Stable list key — never use a null [ValueKey] (collides across replies).
Object _replyListKey(Reply reply) =>
    reply.replyId ?? 'floor_${reply.floor}';

/// Shared [CommentCell] wiring for thread page slivers.
Widget _buildCommentCell(
  BuildContext context,
  ScrollController scrollController,
  ThreadLoaded state,
  Reply reply,
  Function(BuildContext, ScrollController, Reply, bool) onReplySuccess,
) {
  final pageState = BlocProvider.of<ThreadPageCubit>(context).state;
  return CommentCell(
    // Key only on the outer sliver child (Column/KeyedSubtree). Nested
    // PageStorageKey(null) previously collided when replyId was null.
    threadId: state.thread.threadId,
    reply: reply,
    onSent: (sent) {
      onReplySuccess(context, scrollController, sent, pageState.onLastPage);
    },
    threadLocked: state.thread.status == 'locked',
  );
}

Widget _generatePageSliver(
    BuildContext context,
    ScrollController scrollController,
    ThreadLoaded state,
    int index,
    Function(BuildContext, ScrollController, Reply, bool) onReplySuccess) {
  final reply = state.thread.replies[index];
  final isPageStart = reply.floor % 50 == 1;
  final isLast = index == state.thread.replies.length - 1;
  final cell = _buildCommentCell(
      context, scrollController, state, reply, onReplySuccess);

  final key = ValueKey<Object>(_replyListKey(reply));
  if (isPageStart && isLast) {
    return Column(
      key: key,
      children: <Widget>[
        _PageHeader(floor: reply.floor),
        cell,
        _PageFooter(),
      ],
    );
  } else if (isPageStart && state.thread.replies.length != 1) {
    return Column(
      key: key,
      children: <Widget>[
        _PageHeader(floor: reply.floor),
        cell,
      ],
    );
  } else if (isLast) {
    return Column(
      key: key,
      children: <Widget>[
        cell,
        _PageFooter(),
      ],
    );
  } else {
    return KeyedSubtree(
      key: key,
      child: cell,
    );
  }
}
