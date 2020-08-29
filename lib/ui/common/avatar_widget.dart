import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/user_group.dart';

class AvatarWidget extends StatelessWidget {
  final Widget avatarImage;
  final List<UserGroup> userGroup;
  final Function onTap;

  const AvatarWidget(
      {Key key,
      @required this.avatarImage,
      @required this.userGroup,
      this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.fromLTRB(0, 0, 5, 10),
          child: Material(
            shape: CircleBorder(),
            elevation: 6,
            child: Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              child: CircleAvatar(
                radius: 22,
                child: avatarImage,
                backgroundColor: Theme.of(context).primaryColor,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[700],
                gradient: userGroup.isEmpty
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          userGroup.first.groupId == 'ADMIN'
                              ? Color(0xff7435a0)
                              : Color(0xffe0561d),
                          userGroup.first.groupId == 'ADMIN'
                              ? Color(0xff4a72d3)
                              : Color(0xffd8529a)
                        ],
                      ),
              ),
            ),
          ),
        ),
      );
}
