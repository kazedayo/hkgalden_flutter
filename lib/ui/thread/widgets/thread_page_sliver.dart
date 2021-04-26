part of '../thread_page.dart';

Widget _generatePageSliver(
    BuildContext context,
    ScrollController scrollController,
    ThreadLoaded state,
    int index,
    Function(BuildContext, ScrollController, Reply, bool) onReplySuccess) {
  if (state.thread.replies[index].floor % 50 == 1 &&
      state.thread.replies[index] == state.thread.replies.last) {
    return Column(
      children: <Widget>[
        _PageHeader(floor: state.thread.replies[index].floor),
        CommentCell(
          key: PageStorageKey(state.thread.replies[index].replyId),
          threadId: state.thread.threadId,
          reply: state.thread.replies[index],
          onLastPage:
              BlocProvider.of<ThreadPageCubit>(context).state.onLastPage,
          onSent: (reply) {
            onReplySuccess(context, scrollController, reply,
                BlocProvider.of<ThreadPageCubit>(context).state.onLastPage);
          },
          canReply: BlocProvider.of<ThreadPageCubit>(context).state.canReply,
          threadLocked: state.thread.status == 'locked',
        ),
        _PageFooter(
          onLastPage:
              BlocProvider.of<ThreadPageCubit>(context).state.onLastPage,
        )
      ],
    );
  } else if (state.thread.replies[index].floor % 50 == 1 &&
      state.thread.replies.length != 1) {
    return Column(
      children: <Widget>[
        _PageHeader(floor: state.thread.replies[index].floor),
        CommentCell(
          key: PageStorageKey(state.thread.replies[index].replyId),
          threadId: state.thread.threadId,
          reply: state.thread.replies[index],
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
  } else if (index == state.thread.replies.length - 1) {
    return Column(
      children: <Widget>[
        CommentCell(
          key: PageStorageKey(state.thread.replies[index].replyId),
          threadId: state.thread.threadId,
          reply: state.thread.replies[index],
          onLastPage:
              BlocProvider.of<ThreadPageCubit>(context).state.onLastPage,
          onSent: (reply) {
            onReplySuccess(context, scrollController, reply,
                BlocProvider.of<ThreadPageCubit>(context).state.onLastPage);
          },
          canReply: BlocProvider.of<ThreadPageCubit>(context).state.canReply,
          threadLocked: state.thread.status == 'locked',
        ),
        _PageFooter(
          onLastPage:
              BlocProvider.of<ThreadPageCubit>(context).state.onLastPage,
        ),
      ],
    );
  } else {
    return CommentCell(
      key: PageStorageKey(state.thread.replies[index].replyId),
      threadId: state.thread.threadId,
      reply: state.thread.replies[index],
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
