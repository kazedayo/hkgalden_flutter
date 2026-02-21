import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/ui/common/user_avatar_image.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';

import 'package:hkgalden_flutter/ui/common/compose_page/compose_page.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/styled_html_view.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_page.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';

import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import 'package:popover/popover.dart';

part 'widgets/comment_user_info_cluster.dart';

class CommentCell extends StatefulWidget {
  final int threadId;
  final Reply reply;
  final bool onLastPage;
  final Function(Reply) onSent;
  final bool canReply;
  final bool threadLocked;

  const CommentCell(
      {super.key,
      required this.threadId,
      required this.reply,
      required this.onLastPage,
      required this.onSent,
      required this.canReply,
      required this.threadLocked});

  @override
  State<CommentCell> createState() => _CommentCellState();
}

class _CommentCellState extends State<CommentCell> {
  late String _parsedHtml;
  late SessionUserBloc _sessionUserBloc;

  @override
  void initState() {
    super.initState();
    _sessionUserBloc = BlocProvider.of<SessionUserBloc>(context);
    _parseHtml();
  }

  @override
  void didUpdateWidget(covariant CommentCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reply != oldWidget.reply) {
      _parseHtml();
    }
  }

  void _parseHtml() {
    _parsedHtml = HKGaldenHtmlParser()
            .commentWithQuotes(widget.reply, _sessionUserBloc.state) ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: () {
        if (_sessionUserBloc.state is SessionUserLoaded) {
          return !(_sessionUserBloc.state as SessionUserLoaded)
              .sessionUser
              .blockedUsers
              .contains(widget.reply.author.userId);
        } else {
          return true;
        }
      }(),
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(
                height: 33,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color ??
                      Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                          child: StyledHtmlView(
                              htmlString: _parsedHtml,
                              floor: widget.reply.floor)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Transform(
                            transform: Matrix4.translationValues(8, 0, 0),
                            child: Visibility(
                              visible: !widget.threadLocked,
                              child: IconButton(
                                icon: const Icon(Icons.format_quote),
                                onPressed: () => widget.canReply
                                    ? showBarModalBottomSheet(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        animationCurve: Curves.easeOut,
                                        context: context,
                                        builder: (context) => ComposePage(
                                          composeMode: ComposeMode.quotedReply,
                                          threadId: widget.threadId,
                                          parentReply: widget.reply,
                                          onSent: (reply) {
                                            widget.onSent(reply);
                                          },
                                        ),
                                      )
                                    : showCustomDialog(
                                        context: context,
                                        builder: (context) =>
                                            const CustomAlertDialog(
                                          title: '未登入',
                                          content: '請先登入',
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 24,
            top: 19,
            child: Text(
                DateTimeFormat.format(widget.reply.date.toLocal(),
                    format: 'd/m/y H:i'),
                style: Theme.of(context).textTheme.bodySmall),
          ),
          CommentUserInfoCluster(
              reply: widget.reply, sessionUserBloc: _sessionUserBloc)
        ],
      ),
    );
  }
}
