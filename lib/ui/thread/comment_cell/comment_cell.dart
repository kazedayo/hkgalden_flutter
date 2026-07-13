import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/cubit/thread_page_cubit.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/ui_state_models/thread_page_state.dart';
import 'package:hkgalden_flutter/ui/common/compose_page/compose_page.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/styled_html_view.dart';
import 'package:hkgalden_flutter/ui/common/user_avatar_image.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_page.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';
import 'package:hkgalden_flutter/utils/parsed_comment_html_cache.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:popover/popover.dart';

part 'widgets/comment_user_info_cluster.dart';

class CommentCell extends StatefulWidget {
  final int threadId;
  final Reply reply;
  final Function(Reply) onSent;
  final bool threadLocked;

  const CommentCell(
      {super.key,
      required this.threadId,
      required this.reply,
      required this.onSent,
      required this.threadLocked});

  @override
  State<CommentCell> createState() => _CommentCellState();
}

class _CommentCellState extends State<CommentCell>
    with AutomaticKeepAliveClientMixin {
  late SessionUserBloc _sessionUserBloc;

  // No LRU budget — budgeting caused wrong reuse / out-of-order replies.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _sessionUserBloc = BlocProvider.of<SessionUserBloc>(context);
    ParsedCommentHtmlCache.instance
        .getOrParse(widget.reply, _sessionUserBloc.state);
  }

  @override
  void didUpdateWidget(covariant CommentCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reply != oldWidget.reply) {
      ParsedCommentHtmlCache.instance
          .getOrParse(widget.reply, _sessionUserBloc.state);
    }
  }

  bool _isAuthorBlocked(SessionUserState state) {
    if (state is! SessionUserLoaded) {
      return false;
    }
    return state.sessionUser.blockedUsers.contains(widget.reply.author.userId);
  }

  bool _sameBlockedSet(SessionUserState a, SessionUserState b) {
    if (a is SessionUserLoaded && b is SessionUserLoaded) {
      final aBlocked = a.sessionUser.blockedUsers;
      final bBlocked = b.sessionUser.blockedUsers;
      if (identical(aBlocked, bBlocked)) {
        return true;
      }
      if (aBlocked.length != bBlocked.length) {
        return false;
      }
      return Set<String>.from(aBlocked).containsAll(bBlocked);
    }
    return a.runtimeType == b.runtimeType;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<SessionUserBloc, SessionUserState>(
      buildWhen: (prev, next) =>
          _isAuthorBlocked(prev) != _isAuthorBlocked(next) ||
          !_sameBlockedSet(prev, next),
      builder: (context, sessionState) {
        final theme = Theme.of(context);
        final cardColor = theme.cardTheme.color ?? theme.cardColor;
        final dateStyle = theme.textTheme.bodySmall;
        final dateText = DateTimeFormat.format(
          widget.reply.date.toLocal(),
          format: 'd/m/y H:i',
        );
        final html = ParsedCommentHtmlCache.instance
            .getOrParse(widget.reply, sessionState);

        return Visibility(
          visible: !_isAuthorBlocked(sessionState),
          child: RepaintBoundary(
            child: Stack(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 33),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                                child: StyledHtmlView(
                                  htmlString: html,
                                  floor: widget.reply.floor,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                  Transform(
                                    transform:
                                        Matrix4.translationValues(8, 0, 0),
                                    child: Visibility(
                                      visible: !widget.threadLocked,
                                      child: BlocBuilder<ThreadPageCubit,
                                          ThreadPageState>(
                                        buildWhen: (prev, next) =>
                                            prev.canReply != next.canReply,
                                        builder: (context, pageState) {
                                          return IconButton(
                                            icon:
                                                const Icon(Icons.format_quote),
                                            onPressed: () => pageState.canReply
                                                ? showBarModalBottomSheet(
                                                    duration: const Duration(
                                                        milliseconds: 300),
                                                    animationCurve:
                                                        Curves.easeOut,
                                                    context: context,
                                                    builder: (context) =>
                                                        ComposePage(
                                                      composeMode: ComposeMode
                                                          .quotedReply,
                                                      threadId: widget.threadId,
                                                      parentReply: widget.reply,
                                                      onSent: (reply) {
                                                        widget.onSent(reply);
                                                      },
                                                    ),
                                                  )
                                                : showCustomAlert(
                                                    context: context,
                                                    title: '未登入',
                                                    content: '請先登入',
                                                  ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 24,
                  top: 19,
                  child: Text(dateText, style: dateStyle),
                ),
                CommentUserInfoCluster(
                    reply: widget.reply, sessionUserBloc: _sessionUserBloc)
              ],
            ),
          ),
        );
      },
    );
  }
}
