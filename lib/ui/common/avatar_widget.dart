import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/user_group.dart';

class AvatarWidget extends StatelessWidget {
  final Widget avatarImage;
  final List<UserGroup> userGroup;

  const AvatarWidget({
    Key? key,
    required this.avatarImage,
    required this.userGroup,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Material(
        shape: const CircleBorder(),
        elevation: 6,
        clipBehavior: Clip.hardEdge,
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[700],
            gradient: userGroup.isEmpty
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      if (userGroup.first.groupId == 'ADMIN')
                        const Color(0xff7435a0)
                      else
                        const Color(0xffe0561d),
                      if (userGroup.first.groupId == 'ADMIN')
                        const Color(0xff4a72d3)
                      else
                        const Color(0xffd8529a)
                    ],
                  ),
          ),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Theme.of(context).primaryColor,
            child: avatarImage,
          ),
        ),
      );
}
