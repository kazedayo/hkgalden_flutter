import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';

class BlockedUserCell extends StatefulWidget {
  final User user;

  BlockedUserCell({this.user});

  @override
  _BlockedUserCellState createState() => _BlockedUserCellState();
}

class _BlockedUserCellState extends State<BlockedUserCell> {
  bool _unblock;

  @override
  void initState() {
    _unblock = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) => FlatButton(
        onPressed: () {
          setState(() {
            _unblock = !_unblock;
          });
        },
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 8),
          leading: AvatarWidget(
            avatarImage: widget.user.avatar == ''
                ? SvgPicture.asset('assets/icon-hkgalden.svg',
                    width: 30, height: 30, color: Colors.grey)
                : CachedNetworkImage(
                    imageUrl: widget.user.avatar,
                    width: 30,
                    height: 30,
                    fadeInDuration: Duration(milliseconds: 250),
                    fadeOutDuration: Duration(milliseconds: 250),
                  ),
            userGroup: widget.user.userGroup,
          ),
          title: Text(widget.user.nickName,
              style: Theme.of(context).textTheme.bodyText1.copyWith(
                  decoration: _unblock
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationThickness: 2.5,
                  decorationColor: Colors.white,
                  color: widget.user.gender == 'M'
                      ? Theme.of(context).colorScheme.brotherColor
                      : Theme.of(context).colorScheme.sisterColor)),
          trailing: Text(
            widget.user.userId,
            style: Theme.of(context).textTheme.caption,
          ),
        ),
      );
}
