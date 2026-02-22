import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_thread_list_page.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';
import 'package:octo_image/octo_image.dart';

class UserPage extends StatelessWidget {
  final User user;

  const UserPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Card(
            clipBehavior: Clip.hardEdge,
            color: Theme.of(context).primaryColor,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10))),
            elevation: 6,
            margin: const EdgeInsets.only(top: 40),
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
                          width: 25,
                          height: 25,
                          colorFilter: const ColorFilter.mode(
                              Colors.grey, BlendMode.srcIn))
                      : OctoImage(
                          width: 25,
                          height: 25,
                          image: ResizeImage(
                            NetworkImage(user.avatar),
                            width: (25 * MediaQuery.devicePixelRatioOf(context))
                                .toInt(),
                            height:
                                (25 * MediaQuery.devicePixelRatioOf(context))
                                    .toInt(),
                          ),
                          placeholderBuilder: (context) => SizedBox.fromSize(
                            size: const Size.square(30),
                          ),
                        ),
                  userGroup: user.userGroup,
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
                      user.nickName,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: user.gender == 'M'
                              ? Theme.of(context).colorScheme.brotherColor
                              : Theme.of(context).colorScheme.sisterColor),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(user.userId,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
}
