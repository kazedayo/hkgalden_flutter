import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/user_group.dart';

class AvatarWidget extends StatelessWidget {
  final Image avatarImage;
  final List<UserGroup> userGroup;

  const AvatarWidget({Key key, this.avatarImage, this.userGroup}) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
    width: 50,
    height: 50,
    alignment: Alignment.center,
    child: Container(
      padding: EdgeInsets.all(8),
      child: avatarImage,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[850],
      ),
    ),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color:Colors.grey[700],
      gradient: userGroup == null ? null : LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [userGroup.first.groupId == 'ADMIN' ? Color(0xff7435a0) : Color(0xffe0561d),
                  userGroup.first.groupId == 'ADMIN' ? Color(0xff4a72d3) : Color(0xffd8529a)],
      ),
    ),
  );
}