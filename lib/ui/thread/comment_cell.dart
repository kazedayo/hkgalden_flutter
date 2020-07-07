import 'package:animations/animations.dart';
import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/ui/common/compose_page.dart';
import 'package:hkgalden_flutter/ui/common/full_screen_photo_view.dart';
import 'package:hkgalden_flutter/ui/common/styled_html_view.dart';
import 'package:hkgalden_flutter/ui/page_transitions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hkgalden_flutter/viewmodels/thread_page_view_model.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';

class CommentCell extends StatelessWidget {
  final ThreadPageViewModel viewModel;
  final int threadId;
  final Reply reply;
  final bool onLastPage;
  final FullScreenPhotoView photoView = FullScreenPhotoView();
  final Function(Reply) onSent;

  CommentCell(
      {this.viewModel,
      this.threadId,
      this.reply,
      this.onLastPage,
      this.onSent});

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).primaryColor,
        child: Container(
          padding: EdgeInsets.only(top: 16, left: 16, right: 16),
          //height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  AvatarWidget(
                    //舊膠登icon死link會炒async #dead#
                    avatarImage: reply.author.avatar == ''
                        ? SvgPicture.asset('assets/icon-hkgalden.svg',
                            width: 30, height: 30, color: Colors.grey)
                        : CachedNetworkImage(
                            imageUrl: reply.author.avatar,
                            width: 30,
                            height: 30,
                            fadeInDuration: Duration(milliseconds: 300),
                            fadeOutDuration: Duration(milliseconds: 300),
                          ),
                    userGroup: reply.author.userGroup == null
                        ? []
                        : reply.author.userGroup,
                  ),
                  SizedBox(
                    width: 5,
                  ),
                  Text(
                    reply.authorNickname,
                    style: TextStyle(
                      color: reply.author.gender == 'M'
                          ? Theme.of(context).colorScheme.brotherColor
                          : Theme.of(context).colorScheme.sisterColor,
                    ),
                  ),
                  Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text('#${reply.floor}'),
                      Text(DateTimeFormat.format(reply.date.toLocal(),
                          format: 'Y/m/d h:i A')),
                    ],
                  ),
                ],
              ),
              Padding(
                  padding: const EdgeInsets.fromLTRB(0, 5, 0, 0),
                  child: StyledHtmlView(
                      htmlString: HKGaldenHtmlParser().commentWithQuotes(reply),
                      floor: reply.floor)),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  IconButton(
                      icon: Icon(Icons.format_quote),
                      onPressed: () =>
                          Navigator.of(context).push(SlideInFromBottomRoute(
                              page: ComposePage(
                            composeMode: ComposeMode.quotedReply,
                            threadId: threadId,
                            parentReply: reply,
                            onSent: (reply) {
                              onSent(reply);
                            },
                          )))),
                  IconButton(icon: Icon(Icons.block), onPressed: () => null),
                  IconButton(
                      icon: Icon(Icons.flag),
                      onPressed: () => showModal<void>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('回報問題'),
                              content: Text(
                                  '如有任何關於用戶發表內容問題，請電郵至hkgalden.org@gmail.com'),
                              actions: <Widget>[
                                FlatButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: Text('OK'))
                              ],
                            ),
                          )),
                ],
              ),
            ],
          ),
        ),
      );
}
