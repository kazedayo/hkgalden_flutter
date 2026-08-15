import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_thread_list_page.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';
import 'package:octo_image/octo_image.dart';

class UserPage extends StatelessWidget {
  final User user;

  const UserPage({super.key, required this.user});

  bool _isOwnProfile(SessionUserState session) {
    return session is SessionUserLoaded &&
        session.sessionUser.userId == user.userId;
  }

  void _blockUser(BuildContext context) {
    final session = context.read<SessionUserBloc>();
    if (session.state is! SessionUserLoaded) {
      showCustomAlert(
        context: context,
        title: '未登入',
        content: '請先登入',
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    session.add(AppendUserToBlockListEvent(userId: user.userId));
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text('已封鎖會員 ${user.nickName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionUserBloc>().state;
    return Stack(
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
              padding: const EdgeInsets.only(top: 56),
              child: UserThreadListPage(
                userId: user.userId,
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            right: _isOwnProfile(session) ? 16 : 96,
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
          if (!_isOwnProfile(session))
            Positioned(
              right: 16,
              top: 52,
              child: Material(
                color: const Color(0x26FF5252),
                shape: const StadiumBorder(
                  side: BorderSide(color: Color(0x59FF5252)),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _blockUser(context),
                  child: const Padding(
                    padding: EdgeInsets.fromLTRB(10, 6, 12, 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.block_outlined,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 5),
                        Text(
                          '封鎖',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
  }
}
