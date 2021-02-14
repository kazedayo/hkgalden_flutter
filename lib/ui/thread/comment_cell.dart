import 'dart:ui';

import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/cupertino.dart';
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
import 'package:hkgalden_flutter/ui/common/compose_page.dart';
import 'package:hkgalden_flutter/ui/common/full_screen_photo_view.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/styled_html_view.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_page.dart';
import 'package:hkgalden_flutter/utils/keys.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:octo_image/octo_image.dart';
import 'package:paulonia_cache_image/paulonia_cache_image.dart';

class CommentCell extends StatefulWidget {
  final int threadId;
  final Reply reply;
  final bool onLastPage;
  final Function(Reply) onSent;
  final bool canReply;
  final bool threadLocked;

  const CommentCell(
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
  final FullScreenPhotoView photoView = const FullScreenPhotoView();
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
              const SizedBox(
                height: 33,
              ),
              Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                color: Theme.of(context).primaryColor,
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
                                  icon: const Icon(Icons.format_quote),
                                  onPressed: () => widget.canReply
                                      ? showBarModalBottomSheet(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          animationCurve: Curves.easeOut,
                                          context: context,
                                          builder: (context) => ComposePage(
                                            composeMode:
                                                ComposeMode.quotedReply,
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
                                              ))),
                            ),
                          ),
                          // IconButton(
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
                style: Theme.of(context).textTheme.caption),
          ),
          Positioned(
            left: 24,
            top: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Material(
                  elevation: 6,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.hardEdge,
                  child: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        textStyle: Theme.of(context)
                            .textTheme
                            .caption
                            .copyWith(color: Colors.white),
                        value: _MenuItem.memberinfo,
                        child: const ListTile(
                          dense: true,
                          leading: Icon(Icons.account_box_rounded),
                          title: Text('會員檔案'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: _MenuItem.block,
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.block_outlined,
                            color: Colors.redAccent,
                          ),
                          title: Text('封鎖會員'),
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      switch (value as _MenuItem) {
                        case _MenuItem.memberinfo:
                          showMaterialModalBottomSheet(
                              duration: const Duration(milliseconds: 200),
                              animationCurve: Curves.easeOut,
                              backgroundColor: Colors.transparent,
                              barrierColor: Colors.black87,
                              context: context,
                              enableDrag: false,
                              builder: (context) => UserPage(
                                    user: widget.reply.author,
                                  ));
                          break;
                        case _MenuItem.block:
                          StoreProvider.of<AppState>(context)
                                      .state
                                      .sessionUserState
                                      .isLoggedIn ==
                                  false
                              ? showCustomDialog(
                                  builder: (context) => const CustomAlertDialog(
                                      title: "未登入", content: "請先登入"),
                                )
                              : HKGaldenApi()
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
                          break;
                        default:
                      }
                    },
                    child: AvatarWidget(
                      avatarImage: widget.reply.author.avatar == ''
                          ? SvgPicture.asset('assets/icon-hkgalden.svg',
                              width: 25, height: 25, color: Colors.grey)
                          : OctoImage(
                              placeholderBuilder: (context) =>
                                  SizedBox.fromSize(
                                size: const Size.square(30),
                              ),
                              image: PCacheImage(widget.reply.author.avatar),
                              width: 25,
                              height: 25,
                            ),
                      userGroup: widget.reply.author.userGroup ?? [],
                    ),
                  ),
                ),
                const SizedBox(
                  width: 5,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      widget.reply.authorNickname,
                      style: Theme.of(context).textTheme.caption.copyWith(
                            color: widget.reply.author.gender == 'M'
                                ? Theme.of(context).colorScheme.brotherColor
                                : Theme.of(context).colorScheme.sisterColor,
                          ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text('#${widget.reply.floor}',
                        style: Theme.of(context).textTheme.caption),
                  ],
                )
              ],
            ),
          )
        ],
      );
}

enum _MenuItem {
  memberinfo,
  block,
}
