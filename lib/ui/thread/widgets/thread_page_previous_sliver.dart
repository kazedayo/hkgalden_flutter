import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/ui/thread/reply_position_anchor.dart';
import 'package:hkgalden_flutter/ui/thread/widgets/thread_page_header.dart';
import 'package:hkgalden_flutter/ui/thread/widgets/thread_page_sliver.dart';

Widget generatePreviousThreadPageSliver(
  BuildContext context,
  ScrollController scrollController,
  ThreadLoaded state,
  int index,
  ThreadReplySuccessCallback onReplySuccess,
  ReplyAnchorRegistry anchorRegistry,
) {
  final reply = state
      .previousPages.replies[state.previousPages.replies.length - index - 1];
  final cell = buildThreadCommentCell(
    context,
    scrollController,
    state,
    reply,
    onReplySuccess,
    anchorRegistry,
  );

  final key = ValueKey<Object>(replyListKey(reply));
  if (reply.floor % 50 == 1) {
    return Column(
      key: key,
      children: <Widget>[
        ThreadPageHeader(floor: reply.floor),
        cell,
      ],
    );
  }

  return KeyedSubtree(
    key: key,
    child: cell,
  );
}
