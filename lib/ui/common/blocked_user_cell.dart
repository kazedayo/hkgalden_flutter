import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_cubit.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/ui/common/user_avatar_image.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';

class BlockedUserCell extends StatelessWidget {
  final User user;
  final VoidCallback? onUnblocked;

  const BlockedUserCell({
    super.key,
    required this.user,
    this.onUnblocked,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(user.userId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.redAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Text(
          '解除封鎖',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      confirmDismiss: (_) async {
        final ok = await context
            .read<SessionUserCubit>()
            .removeUserFromBlockList(user.userId);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('解除封鎖失敗')),
          );
        }
        return ok;
      },
      onDismissed: (_) => onUnblocked?.call(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: UserAvatarImage(
          avatarUrl: user.avatar,
          userGroup: user.userGroup,
          size: 30,
        ),
        title: Text(
          user.nickName,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: user.gender == 'M'
                    ? AppTheme.brotherColor
                    : AppTheme.sisterColor,
              ),
        ),
        trailing: Text(
          user.userId,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
