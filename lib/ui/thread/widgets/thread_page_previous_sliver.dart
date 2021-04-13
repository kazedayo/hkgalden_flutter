part of '../thread_page.dart';

Widget _generatePreviousPageSliver(ThreadLoaded state, int index, int page,
    bool onLastPage, bool canReply, Function(Reply) onReplySuccess) {
  if (state.previousPages.replies.isEmpty) {
    return Visibility(
      visible: page != 1,
      child: ThreadPageLoadingSkeletonCell(),
    );
  } else {
    if (state.previousPages
                .replies[state.previousPages.replies.length - index - 1].floor %
            50 ==
        1) {
      return Column(
        children: <Widget>[
          if (state
                      .previousPages
                      .replies[state.previousPages.replies.length - index - 1]
                      .floor !=
                  1 &&
              (state
                              .previousPages
                              .replies[state.previousPages.replies.length -
                                  index -
                                  1]
                              .floor /
                          50.0)
                      .ceil() ==
                  state.currentPage)
            ThreadPageLoadingSkeletonCell(),
          _PageHeader(
            floor: state.previousPages
                .replies[state.previousPages.replies.length - index - 1].floor,
          ),
          CommentCell(
            key: ValueKey(state
                .previousPages
                .replies[state.previousPages.replies.length - index - 1]
                .replyId),
            threadId: state.thread.threadId,
            reply: state.previousPages
                .replies[state.previousPages.replies.length - index - 1],
            onLastPage: onLastPage,
            onSent: (reply) {
              onReplySuccess(reply);
            },
            canReply: canReply,
            threadLocked: state.thread.status == 'locked',
          ),
        ],
      );
    } else {
      return CommentCell(
        key: ValueKey(state.previousPages
            .replies[state.previousPages.replies.length - index - 1].replyId),
        threadId: state.thread.threadId,
        reply: state.previousPages
            .replies[state.previousPages.replies.length - index - 1],
        onLastPage: onLastPage,
        onSent: (reply) {
          onReplySuccess(reply);
        },
        canReply: canReply,
        threadLocked: state.thread.status == 'locked',
      );
    }
  }
}
