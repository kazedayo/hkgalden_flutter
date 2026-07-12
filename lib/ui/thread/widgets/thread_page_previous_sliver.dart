part of '../thread_page.dart';

Widget _generatePreviousPageSliver(
    BuildContext context,
    ScrollController scrollController,
    ThreadLoaded state,
    int index,
    int page,
    Function(BuildContext, ScrollController, Reply, bool) onReplySuccess) {
  if (state.previousPages.replies.isEmpty) {
    return Visibility(
      visible: page != 1,
      child: ThreadPageLoadingSkeletonCell(),
    );
  }

  final reply =
      state.previousPages.replies[state.previousPages.replies.length - index - 1];
  final cell = _buildCommentCell(
      context, scrollController, state, reply, onReplySuccess);

  if (reply.floor % 50 == 1) {
    return Column(
      key: ValueKey(reply.replyId),
      children: <Widget>[
        if (reply.floor != 1 && (reply.floor / 50.0).ceil() == state.currentPage)
          ThreadPageLoadingSkeletonCell(),
        _PageHeader(floor: reply.floor),
        cell,
      ],
    );
  }

  // Match findChildIndexCallback (ValueKey) for stable element reuse on prepend.
  return KeyedSubtree(
    key: ValueKey(reply.replyId),
    child: cell,
  );
}
