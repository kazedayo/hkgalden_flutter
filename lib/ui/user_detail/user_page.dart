import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_cubit.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/ui/common/custom_alert_dialog.dart';
import 'package:hkgalden_flutter/ui/common/user_avatar_image.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_thread_list_page.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';

class UserPage extends StatelessWidget {
  final User user;

  const UserPage({super.key, required this.user});

  bool _isOwnProfile(SessionUserState session) {
    return session is SessionUserLoaded &&
        session.sessionUser.userId == user.userId;
  }

  void _blockUser(BuildContext context) {
    final session = context.read<SessionUserCubit>();
    if (session.state is! SessionUserLoaded) {
      showCustomAlert(
        context: context,
        title: '未登入',
        content: '請先登入',
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    session.appendUserToBlockList(user.userId);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text('已封鎖會員 ${user.nickName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionUserCubit>().state;
    final theme = Theme.of(context);
    final ownProfile = _isOwnProfile(session);

    return Stack(
      children: [
        Card(
          clipBehavior: Clip.hardEdge,
          color: theme.primaryColor,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10))),
          elevation: 6,
          margin: const EdgeInsets.only(top: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  '主題列表',
                  style: theme.textTheme.titleSmall!.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              UserThreadListPage(
                userId: user.userId,
              ),
            ],
          ),
        ),
        Positioned(
          left: 16,
          top: 12,
          right: 12,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              UserAvatarImage(
                avatarUrl: user.avatar,
                userGroup: user.userGroup,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.nickName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge!.copyWith(
                          height: 1.2,
                          color: user.gender == 'M'
                              ? theme.colorScheme.brotherColor
                              : theme.colorScheme.sisterColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.userId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall!.copyWith(
                        height: 1.2,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!ownProfile) ...[
                const SizedBox(width: 8),
                Material(
                  color: Colors.redAccent,
                  elevation: 6,
                  shadowColor: Colors.black54,
                  shape: const StadiumBorder(),
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
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Text(
                            '封鎖',
                            style: TextStyle(
                              color: Colors.white,
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
              ],
            ],
          ),
        ),
      ],
    );
  }
}
