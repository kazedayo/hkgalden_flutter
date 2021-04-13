part of '../thread_page.dart';

Widget _generatePageSliver(ThreadLoaded state, int index, bool onLastPage,
    bool canReply, Function(Reply) onReplySuccess) {
  if (state.thread.replies[index].floor % 50 == 1 &&
      state.thread.replies[index] == state.thread.replies.last) {
    return Column(
      children: <Widget>[
        _PageHeader(floor: state.thread.replies[index].floor),
        CommentCell(
          key: ValueKey(state.thread.replies[index].replyId),
          threadId: state.thread.threadId,
          reply: state.thread.replies[index],
          onLastPage: onLastPage,
          onSent: (reply) {
            onReplySuccess(reply);
          },
          canReply: canReply,
          threadLocked: state.thread.status == 'locked',
        ),
        _PageFooter(
          onLastPage: onLastPage,
        )
      ],
    );
  } else if (state.thread.replies[index].floor % 50 == 1 &&
      state.thread.replies.length != 1) {
    return Column(
      children: <Widget>[
        _PageHeader(floor: state.thread.replies[index].floor),
        CommentCell(
          key: ValueKey(state.thread.replies[index].replyId),
          threadId: state.thread.threadId,
          reply: state.thread.replies[index],
          onLastPage: onLastPage,
          onSent: (reply) {
            onReplySuccess(reply);
          },
          canReply: canReply,
          threadLocked: state.thread.status == 'locked',
        ),
      ],
    );
  } else if (index == state.thread.replies.length - 1) {
    return Column(
      children: <Widget>[
        CommentCell(
          key: ValueKey(state.thread.replies[index].replyId),
          threadId: state.thread.threadId,
          reply: state.thread.replies[index],
          onLastPage: onLastPage,
          onSent: (reply) {
            onReplySuccess(reply);
          },
          canReply: canReply,
          threadLocked: state.thread.status == 'locked',
        ),
        _PageFooter(
          onLastPage: onLastPage,
        ),
      ],
    );
  } else {
    return CommentCell(
      key: ValueKey(state.thread.replies[index].replyId),
      threadId: state.thread.threadId,
      reply: state.thread.replies[index],
      onLastPage: onLastPage,
      onSent: (reply) {
        onReplySuccess(reply);
      },
      canReply: canReply,
      threadLocked: state.thread.status == 'locked',
    );
  }
}
