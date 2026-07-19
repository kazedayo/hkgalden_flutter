import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/cubit/thread_page_cubit.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/ui/thread/comment_cell/comment_cell.dart';
import 'package:hkgalden_flutter/ui/thread/reply_position_anchor.dart';
import 'package:hkgalden_flutter/ui/thread/widgets/thread_page_footer.dart';
import 'package:hkgalden_flutter/ui/thread/widgets/thread_page_header.dart';

Object replyListKey(Reply reply) => reply.replyId ?? 'floor_${reply.floor}';

typedef ThreadReplySuccessCallback = void Function(
  BuildContext context,
  ScrollController scrollController,
  Reply reply,
  bool onLastPage,
);

Widget buildThreadCommentCell(
  BuildContext context,
  ScrollController scrollController,
  ThreadLoaded state,
  Reply reply,
  ThreadReplySuccessCallback onReplySuccess,
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

Widget generateThreadPageSliver(
  BuildContext context,
  ScrollController scrollController,
  ThreadLoaded state,
  List<Reply> replies,
  int index,
  ThreadReplySuccessCallback onReplySuccess,
  ReplyAnchorRegistry anchorRegistry, {
  required bool isTrailingWindow,
  GlobalKey? footerMeasureKey,
}) {
  final reply = replies[index];
  final isPageStart = reply.floor % 50 == 1;
  final isLast = isTrailingWindow && index == replies.length - 1;
  final cell = buildThreadCommentCell(
    context,
    scrollController,
    state,
    reply,
    onReplySuccess,
    anchorRegistry,
  );
  final footer = isLast
      ? ThreadPageFooter(measureKey: footerMeasureKey)
      : null;

  final key = ValueKey<Object>(replyListKey(reply));
  if (isPageStart && isLast) {
    return Column(
      key: key,
      children: <Widget>[
        ThreadPageHeader(floor: reply.floor),
        cell,
        footer!,
      ],
    );
  } else if (isPageStart && !(isLast && replies.length == 1)) {
    return Column(
      key: key,
      children: <Widget>[
        ThreadPageHeader(floor: reply.floor),
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
