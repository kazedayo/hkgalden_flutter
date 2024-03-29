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
            key: PageStorageKey(state
                .previousPages
                .replies[state.previousPages.replies.length - index - 1]
                .replyId),
            threadId: state.thread.threadId,
            reply: state.previousPages
                .replies[state.previousPages.replies.length - index - 1],
            onLastPage:
                BlocProvider.of<ThreadPageCubit>(context).state.onLastPage,
            onSent: (reply) {
              onReplySuccess(context, scrollController, reply,
                  BlocProvider.of<ThreadPageCubit>(context).state.onLastPage);
            },
            canReply: BlocProvider.of<ThreadPageCubit>(context).state.canReply,
            threadLocked: state.thread.status == 'locked',
          ),
        ],
      );
    } else {
      return CommentCell(
        key: PageStorageKey(state.previousPages
            .replies[state.previousPages.replies.length - index - 1].replyId),
        threadId: state.thread.threadId,
        reply: state.previousPages
            .replies[state.previousPages.replies.length - index - 1],
        onLastPage: BlocProvider.of<ThreadPageCubit>(context).state.onLastPage,
        onSent: (reply) {
          onReplySuccess(context, scrollController, reply,
              BlocProvider.of<ThreadPageCubit>(context).state.onLastPage);
        },
        canReply: BlocProvider.of<ThreadPageCubit>(context).state.canReply,
        threadLocked: state.thread.status == 'locked',
      );
    }
  }
}
