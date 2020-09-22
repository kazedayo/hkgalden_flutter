import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/session_user/session_user_action.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/ui/common/context_menu_button.dart';
import 'package:hkgalden_flutter/ui/common/full_screen_photo_view.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/styled_html_view.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_page.dart';
import 'package:hkgalden_flutter/utils/keys.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';

class CommentCell extends StatefulWidget {
  final int threadId;
  final Reply reply;
  final bool onLastPage;
  final Function(Reply) onSent;
  final bool canReply;
  final bool threadLocked;

  CommentCell(
      {Key key,
      this.threadId,
      this.reply,
      this.onLastPage,
      this.onSent,
      this.canReply,
      this.threadLocked})
      : super(key: key);

  @override
  _CommentCellState createState() => _CommentCellState();
}

class _CommentCellState extends State<CommentCell> {
  final FullScreenPhotoView photoView = FullScreenPhotoView();
  final ContextMenuButtonController _controller = ContextMenuButtonController();
  bool _blockedButtonPressed;

  @override
  void initState() {
    _blockedButtonPressed = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: 33,
              ),
              Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
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
                                  .commentWithQuotes(widget.reply,
                                      StoreProvider.of<AppState>(context)),
                              floor: widget.reply.floor)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Transform(
                            transform: Matrix4.translationValues(8, 0, 0),
                            child: Visibility(
                              visible: !widget.threadLocked,
                              child: IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: Icon(Icons.format_quote),
                                  onPressed: () => widget.canReply
                                      ? Navigator.of(context)
                                          .pushNamed('/Compose',
                                              arguments: ComposePageArguments(
                                                composeMode:
                                                    ComposeMode.quotedReply,
                                                threadId: widget.threadId,
                                                parentReply: widget.reply,
                                                onSent: (reply) {
                                                  widget.onSent(reply);
                                                },
                                              ))
                                      : showModal<void>(
                                          context: context,
                                          builder: (context) =>
                                              CustomAlertDialog(
                                                title: '未登入',
                                                content: '請先登入',
                                              ))),
                            ),
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
              DateTimeFormat.format(widget.reply.date.toLocal(),
                  format: 'd/m/y H:i'),
              style: Theme.of(context)
                  .textTheme
                  .caption
                  .copyWith(shadows: [Shadow(offset: Offset(1, 1))]),
            ),
          ),
          Positioned(
            left: 24,
            top: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ContextMenuButton(
                  controller: _controller,
                  width: 125,
                  height: 70,
                  xOffset: 0,
                  yOffset: 0,
                  closedChild: AvatarWidget(
                    //舊膠登icon死link會炒async #dead#
                    avatarImage: widget.reply.author.avatar == ''
                        ? SvgPicture.asset('assets/icon-hkgalden.svg',
                            width: 25, height: 25, color: Colors.grey)
                        : CachedNetworkImage(
                            placeholder: (context, url) => SizedBox.fromSize(
                              size: Size.square(30),
                            ),
                            imageUrl: widget.reply.author.avatar,
                            width: 25,
                            height: 25,
                          ),
                    userGroup: widget.reply.author.userGroup == null
                        ? []
                        : widget.reply.author.userGroup,
                    onTap: _controller.toggleMenu,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.block, color: Colors.redAccent),
                        onPressed: _blockedButtonPressed ||
                                StoreProvider.of<AppState>(context)
                                        .state
                                        .sessionUserState
                                        .isLoggedIn ==
                                    false
                            ? null
                            : () {
                                _controller.toggleMenu();
                                setState(() {
                                  _blockedButtonPressed =
                                      !_blockedButtonPressed;
                                });
                                HKGaldenApi()
                                    .blockUser(widget.reply.author.userId)
                                    .then((isSuccess) {
                                  setState(() {
                                    _blockedButtonPressed =
                                        !_blockedButtonPressed;
                                  });
                                  if (isSuccess) {
                                    StoreProvider.of<AppState>(context)
                                        .dispatch(AppendUserToBlockListAction(
                                            widget.reply.author.userId));
                                    scaffoldKey.currentState.showSnackBar(SnackBar(
                                        content: Text(
                                            '已封鎖會員 ${widget.reply.authorNickname}')));
                                  } else {}
                                });
                              },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.account_box,
                          color: Colors.black87,
                        ),
                        onPressed: () {
                          _controller.toggleMenu();
                          showModalBottomSheet(
                              backgroundColor: Colors.transparent,
                              barrierColor: Colors.black87,
                              context: context,
                              builder: (context) => UserPage(
                                    user: widget.reply.author,
                                  ));
                        },
                      )
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.reply.authorNickname,
                      style: Theme.of(context).textTheme.caption.copyWith(
                          color: widget.reply.author.gender == 'M'
                              ? Theme.of(context).colorScheme.brotherColor
                              : Theme.of(context).colorScheme.sisterColor,
                          shadows: [Shadow(offset: Offset(1, 1))]),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text('#${widget.reply.floor}',
                        style: Theme.of(context)
                            .textTheme
                            .caption
                            .copyWith(shadows: [Shadow(offset: Offset(1, 1))])),
                    SizedBox(
                      height: 6,
                    )
                  ],
                )
              ],
            ),
          )
        ],
      );
}
