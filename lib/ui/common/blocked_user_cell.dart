import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/ui/common/user_avatar_image.dart';
import 'package:hkgalden_flutter/utils/app_color_scheme.dart';

class BlockedUserCell extends StatefulWidget {
  final User user;

  const BlockedUserCell({super.key, required this.user});

  @override
  State<BlockedUserCell> createState() => _BlockedUserCellState();
}

class _BlockedUserCellState extends State<BlockedUserCell> {
  bool _unblocked = false;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => setState(() => _unblocked = !_unblocked),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: UserAvatarImage(
            avatarUrl: widget.user.avatar,
            userGroup: widget.user.userGroup,
            size: 30,
          ),
          title: Text(widget.user.nickName,
              style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  decoration: _unblocked
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationThickness: 2.5,
                  decorationColor: Colors.white,
                  color: widget.user.gender == 'M'
                      ? Theme.of(context).colorScheme.brotherColor
                      : Theme.of(context).colorScheme.sisterColor)),
          trailing: Text(
            widget.user.userId,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
}
