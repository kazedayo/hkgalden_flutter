import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/ui/common/full_screen_photo_view.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/styled_html_view.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_detail_view.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';

class CommentCell extends StatelessWidget {
  final int threadId;
  final Reply reply;
  final bool onLastPage;
  final FullScreenPhotoView photoView = FullScreenPhotoView();
  final Function(Reply) onSent;
  final bool canReply;

  CommentCell(
      {Key key,
      this.threadId,
      this.reply,
      this.onLastPage,
      this.onSent,
      this.canReply})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: 33,
              ),
              Card(
                elevation: 6,
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
                color: Theme.of(context).primaryColor,
                child: Container(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Padding(
                          padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                          child: StyledHtmlView(
                              htmlString: HKGaldenHtmlParser()
                                  .commentWithQuotes(reply,
                                      StoreProvider.of<AppState>(context)),
                              floor: reply.floor)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Transform(
                            transform: Matrix4.translationValues(8, 0, 0),
                            child: IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: Icon(Icons.format_quote),
                                onPressed: () => canReply
                                    ? Navigator.of(context).pushNamed(
                                        '/Compose',
                                        arguments: ComposePageArguments(
                                          composeMode: ComposeMode.quotedReply,
                                          threadId: threadId,
                                          parentReply: reply,
                                          onSent: (reply) {
                                            onSent(reply);
                                          },
                                        ))
                                    : showModal<void>(
                                        context: context,
                                        builder: (context) => CustomAlertDialog(
                                              title: '未登入',
                                              content: '請先登入',
                                            ))),
                          ),
                          // IconButton(
                          //     visualDensity: VisualDensity.compact,
                          //     icon: Icon(Icons.flag),
                          //     onPressed: () => showModal<void>(
                          //           context: context,
                          //           builder: (context) => AlertDialog(
                          //             title: Text('回報問題'),
                          //             content: Text(
                          //                 '如有任何關於用戶發表內容問題，請電郵至hkgalden.org@gmail.com'),
                          //             actions: <Widget>[
                          //               FlatButton(
                          //                   onPressed: () =>
                          //                       Navigator.of(context).pop(),
                          //                   child: Text('OK'))
                          //             ],
                          //           ),
                          //         )),
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
              DateTimeFormat.format(reply.date.toLocal(), format: 'd/m/y H:i'),
              style: Theme.of(context)
                  .textTheme
                  .caption
                  .copyWith(shadows: [Shadow(blurRadius: 5)]),
            ),
          ),
          Positioned(
            left: 24,
            top: 8,
            child: Row(
              children: [
                AvatarWidget(
                  //舊膠登icon死link會炒async #dead#
                  avatarImage: reply.author.avatar == ''
                      ? SvgPicture.asset('assets/icon-hkgalden.svg',
                          width: 25, height: 25, color: Colors.grey)
                      : CachedNetworkImage(
                          placeholder: (context, url) => SizedBox.fromSize(
                            size: Size.square(30),
                          ),
                          imageUrl: reply.author.avatar,
                          width: 25,
                          height: 25,
                        ),
                  userGroup: reply.author.userGroup == null
                      ? []
                      : reply.author.userGroup,
                  onTap: () => showModal<void>(
                      context: context,
                      builder: (context) => UserDetailView(user: reply.author)),
                ),
                SizedBox(
                  width: 5,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 5,
                    ),
                    Text(
                      reply.authorNickname,
                      style: Theme.of(context).textTheme.caption.copyWith(
                          color: reply.author.gender == 'M'
                              ? Theme.of(context).colorScheme.brotherColor
                              : Theme.of(context).colorScheme.sisterColor,
                          shadows: [Shadow(blurRadius: 5)]),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text('#${reply.floor}',
                        style: Theme.of(context)
                            .textTheme
                            .caption
                            .copyWith(shadows: [Shadow(blurRadius: 5)])),
                  ],
                )
              ],
            ),
          )
        ],
      );
}
