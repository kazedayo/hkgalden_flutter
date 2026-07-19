part of '../thread_page.dart';

Object _replyListKey(Reply reply) =>
    reply.replyId ?? 'floor_${reply.floor}';

Widget _buildCommentCell(
  BuildContext context,
  ScrollController scrollController,
  ThreadLoaded state,
  Reply reply,
  Function(BuildContext, ScrollController, Reply, bool) onReplySuccess,
  ReplyAnchorRegistry anchorRegistry,
) {
  final pageState = BlocProvider.of<ThreadPageCubit>(context).state;
  return ReplyPositionAnchor(
    floor: reply.floor,
    registry: anchorRegistry,
    child: CommentCell(
      threadId: state.thread.threadId,
      reply: reply,
      onSent: (sent) {
        onReplySuccess(context, scrollController, sent, pageState.onLastPage);
      },
      threadLocked: state.thread.status == 'locked',
    ),
  );
}

Widget _generatePageSliver(
  BuildContext context,
  ScrollController scrollController,
  ThreadLoaded state,
  List<Reply> replies,
  int index,
  Function(BuildContext, ScrollController, Reply, bool) onReplySuccess,
  ReplyAnchorRegistry anchorRegistry, {
  required bool isTrailingWindow,
  GlobalKey? footerMeasureKey,
}) {
  final reply = replies[index];
  final isPageStart = reply.floor % 50 == 1;
  final isLast = isTrailingWindow && index == replies.length - 1;
  final cell = _buildCommentCell(context, scrollController, state, reply,
      onReplySuccess, anchorRegistry);
  final footer = isLast
      ? _PageFooter(measureKey: footerMeasureKey)
      : null;

  final key = ValueKey<Object>(_replyListKey(reply));
  if (isPageStart && isLast) {
    return Column(
      key: key,
      children: <Widget>[
        _PageHeader(floor: reply.floor),
        cell,
        footer!,
      ],
    );
  } else if (isPageStart && !(isLast && replies.length == 1)) {
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
        footer!,
      ],
    );
  } else {
    return KeyedSubtree(
      key: key,
      child: cell,
    );
  }
}
