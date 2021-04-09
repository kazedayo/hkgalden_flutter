import 'dart:ui';

import 'package:date_time_format/date_time_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/enums/compose_mode.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/parser/hkgalden_html_parser.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/ui/common/compose_page.dart';
import 'package:hkgalden_flutter/ui/common/full_screen_photo_view.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/styled_html_view.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_page.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:octo_image/octo_image.dart';

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
      {Key? key,
      required this.threadId,
      required this.reply,
      required this.onLastPage,
      required this.onSent,
      required this.canReply,
      required this.threadLocked})
      : super(key: key);

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
                                            composeMode:
                                                ComposeMode.quotedReply,
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
                DateTimeFormat.format(reply.date.toLocal(),
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
                            .caption!
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
                      switch (value! as _MenuItem) {
                        case _MenuItem.memberinfo:
                          showMaterialModalBottomSheet(
                              duration: const Duration(milliseconds: 200),
                              animationCurve: Curves.easeOut,
                              backgroundColor: Colors.transparent,
                              barrierColor: Colors.black87,
                              context: context,
                              enableDrag: false,
                              builder: (context) => UserPage(
                                    user: reply.author,
                                  ));
                          break;
                        case _MenuItem.block:
                          sessionUserBloc.state is! SessionUserLoaded
                              ? showCustomDialog(
                                  context: context,
                                  builder: (context) => const CustomAlertDialog(
                                      title: "未登入", content: "請先登入"),
                                )
                              : HKGaldenApi()
                                  .blockUser(reply.author.userId)
                                  .then((isSuccess) {
                                  if (isSuccess!) {
                                    sessionUserBloc.add(
                                        AppendUserToBlockListEvent(
                                            userId: reply.author.userId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                '已封鎖會員 ${reply.authorNickname}')));
                                  } else {}
                                });
                          break;
                        default:
                      }
                    },
                    child: AvatarWidget(
                      avatarImage: reply.author.avatar == ''
                          ? SvgPicture.asset('assets/icon-hkgalden.svg',
                              width: 25, height: 25, color: Colors.grey)
                          : OctoImage(
                              placeholderBuilder: (context) =>
                                  SizedBox.fromSize(
                                size: const Size.square(30),
                              ),
                              image: NetworkImage(reply.author.avatar),
                              width: 25,
                              height: 25,
                            ),
                      userGroup: reply.author.userGroup,
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
                      reply.authorNickname,
                      style: Theme.of(context).textTheme.caption!.copyWith(
                            color: reply.author.gender == 'M'
                                ? Theme.of(context).colorScheme.brotherColor
                                : Theme.of(context).colorScheme.sisterColor,
                          ),
                    ),
                    const SizedBox(
                      height: 3,
                    ),
                    Text('#${reply.floor}',
                        style: Theme.of(context).textTheme.caption),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

enum _MenuItem {
  memberinfo,
  block,
}
