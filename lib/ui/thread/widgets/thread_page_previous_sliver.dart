part of '../thread_page.dart';

Widget _generatePreviousPageSliver(
    BuildContext context,
    ScrollController scrollController,
    ThreadLoaded state,
    int index,
    Function(BuildContext, ScrollController, Reply, bool) onReplySuccess,
    _ReplyAnchorRegistry anchorRegistry) {
  // Empty previous history has no in-list skeleton — that affordance is the
  // overscroll pull indicator on ThreadPage (not parkable scroll content).
  final reply =
      state.previousPages.replies[state.previousPages.replies.length - index - 1];
  final cell = _buildCommentCell(context, scrollController, state, reply,
      onReplySuccess, anchorRegistry);

  final key = ValueKey<Object>(_replyListKey(reply));
  if (reply.floor % 50 == 1) {
    return Column(
      key: key,
      children: <Widget>[
        _PageHeader(floor: reply.floor),
        cell,
      ],
    );
  }

  // Match findChildIndexCallback (ValueKey) for stable element reuse on prepend.
  return KeyedSubtree(
    key: key,
    child: cell,
  );
}
