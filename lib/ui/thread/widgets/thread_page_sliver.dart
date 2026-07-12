part of '../thread_page.dart';

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
    key: PageStorageKey(reply.replyId),
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

  if (isPageStart && isLast) {
    return Column(
      key: ValueKey(reply.replyId),
      children: <Widget>[
        _PageHeader(floor: reply.floor),
        cell,
        _PageFooter(),
      ],
    );
  } else if (isPageStart && state.thread.replies.length != 1) {
    return Column(
      key: ValueKey(reply.replyId),
      children: <Widget>[
        _PageHeader(floor: reply.floor),
        cell,
      ],
    );
  } else if (isLast) {
    return Column(
      key: ValueKey(reply.replyId),
      children: <Widget>[
        cell,
        _PageFooter(),
      ],
    );
  } else {
    return KeyedSubtree(
      key: ValueKey(reply.replyId),
      child: cell,
    );
  }
}
