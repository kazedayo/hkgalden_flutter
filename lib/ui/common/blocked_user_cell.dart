import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hkgalden_flutter/bloc/cubit/blocked_user_cell_cubit.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/ui/common/user_avatar_image.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';

class BlockedUserCell extends StatelessWidget {
  final User user;

  const BlockedUserCell({super.key, required this.user});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => BlockedUserCellCubit(),
        child: BlocBuilder<BlockedUserCellCubit, bool>(
          builder: (context, state) => TextButton(
            onPressed: () {
              BlocProvider.of<BlockedUserCellCubit>(context)
                  .setUnblockState(!state);
            },
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              leading: UserAvatarImage(
                avatarUrl: user.avatar,
                userGroup: user.userGroup,
                size: 30,
              ),
              title: Text(user.nickName,
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      decoration: state
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationThickness: 2.5,
                      decorationColor: Colors.white,
                      color: user.gender == 'M'
                          ? Theme.of(context).colorScheme.brotherColor
                          : Theme.of(context).colorScheme.sisterColor)),
              trailing: Text(
                user.userId,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      );
}
