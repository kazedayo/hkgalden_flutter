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
import 'package:hkgalden_flutter/ui/common/full_screen_photo_view.dart';
import 'package:hkgalden_flutter/ui/common/styled_html_view.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_page.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';

import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

import 'package:popover/popover.dart';

part 'widgets/comment_user_info_cluster.dart';

class CommentCell extends StatelessWidget {
  final int threadId;
  final Reply reply;
  final bool onLastPage;
  final Function(Reply) onSent;
  final bool canReply;
  final bool threadLocked;
  // ignore: avoid_field_initializers_in_const_classes
  final FullScreenPhotoView photoView = const FullScreenPhotoView();

  const CommentCell(
      {super.key,
      required this.threadId,
      required this.reply,
      required this.onLastPage,
      required this.onSent,
      required this.canReply,
      required this.threadLocked});

  @override
  Widget build(BuildContext context) {
    final SessionUserBloc sessionUserBloc =
        BlocProvider.of<SessionUserBloc>(context);
    return Visibility(
      visible: () {
        if (sessionUserBloc.state is SessionUserLoaded) {
          return !(sessionUserBloc.state as SessionUserLoaded)
              .sessionUser
              .blockedUsers
              .contains(reply.author.userId);
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
              Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                // shape and color defined in AppTheme cardTheme
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                          child: StyledHtmlView(
                              htmlString: HKGaldenHtmlParser()
                                  .commentWithQuotes(
                                      reply, sessionUserBloc.state)!,
                              floor: reply.floor)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Transform(
                            transform: Matrix4.translationValues(8, 0, 0),
                            child: Visibility(
                              visible: !threadLocked,
                              child: IconButton(
                                icon: const Icon(Icons.format_quote),
                                onPressed: () => canReply
                                    ? showBarModalBottomSheet(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        animationCurve: Curves.easeOut,
                                        context: context,
                                        builder: (context) => ComposePage(
                                          composeMode: ComposeMode.quotedReply,
                                          threadId: threadId,
                                          parentReply: reply,
                                          onSent: (reply) {
                                            onSent(reply);
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
                DateTimeFormat.format(reply.date.toLocal(),
                    format: 'd/m/y H:i'),
                style: Theme.of(context).textTheme.bodySmall),
          ),
          CommentUserInfoCluster(reply: reply, sessionUserBloc: sessionUserBloc)
        ],
      ),
    );
  }
}
