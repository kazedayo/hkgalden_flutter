import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hkgalden_flutter/bloc/cubit/blocked_user_cell_cubit.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';
import 'package:octo_image/octo_image.dart';

class BlockedUserCell extends StatelessWidget {
  final User user;

  const BlockedUserCell({required this.user});

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
              leading: AvatarWidget(
                avatarImage: user.avatar == ''
                    ? SvgPicture.asset('assets/icon-hkgalden.svg',
                        width: 30, height: 30, color: Colors.grey)
                    : OctoImage(
                        width: 30,
                        height: 30,
                        image: NetworkImage(user.avatar),
                        placeholderBuilder: (context) => SizedBox.fromSize(
                          size: const Size.square(30),
                        ),
                      ),
                userGroup: user.userGroup,
              ),
              title: Text(user.nickName,
                  style: Theme.of(context).textTheme.bodyText1!.copyWith(
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
                style: Theme.of(context).textTheme.caption,
              ),
            ),
          ),
        ),
      );
}
