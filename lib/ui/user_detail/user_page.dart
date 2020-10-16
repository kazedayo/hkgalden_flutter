import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_thread_list_page.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';

class UserPage extends StatelessWidget {
  final User user;

  const UserPage({Key key, @required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Card(
            clipBehavior: Clip.hardEdge,
            color: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10))),
            elevation: 6,
            margin: EdgeInsets.only(top: 40),
            child: Padding(
              padding: const EdgeInsets.only(top: 30),
              child: UserThreadListPage(
                userId: user.userId,
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarWidget(
                  avatarImage: user.avatar == ''
                      ? SvgPicture.asset('assets/icon-hkgalden.svg',
                          width: 30, height: 30, color: Colors.grey)
                      : CachedNetworkImage(
                          width: 30,
                          height: 30,
                          imageUrl: user.avatar,
                          placeholder: (context, url) => SizedBox.fromSize(
                            size: Size.square(30),
                          ),
                        ),
                  userGroup: user.userGroup,
                ),
                SizedBox(
                  width: 5,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 3,
                    ),
                    Text(
                      user.nickName,
                      style: Theme.of(context).textTheme.bodyText1.copyWith(
                          color: user.gender == 'M'
                              ? Theme.of(context).colorScheme.brotherColor
                              : Theme.of(context).colorScheme.sisterColor),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Text(user.userId,
                        style: Theme.of(context).textTheme.caption),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
}
