import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hkgalden_flutter/models/user_group.dart';
import 'package:hkgalden_flutter/ui/common/avatar_widget.dart';
import 'package:octo_image/octo_image.dart';

/// Combines [AvatarWidget] with the SVG-fallback / [OctoImage] network-load
/// logic so callers only need to pass an [avatarUrl] string.
///
/// When [avatarUrl] is empty the default HKGalden SVG icon is shown instead.
class UserAvatarImage extends StatelessWidget {
  final String avatarUrl;
  final List<UserGroup> userGroup;
  final double size;

  const UserAvatarImage({
    super.key,
    required this.avatarUrl,
    required this.userGroup,
    this.size = 25,
  });

  @override
  Widget build(BuildContext context) => AvatarWidget(
        userGroup: userGroup,
        avatarImage: avatarUrl.isEmpty
            ? SvgPicture.asset(
                'assets/icon-hkgalden.svg',
                width: size,
                height: size,
                colorFilter:
                    const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
              )
            : OctoImage(
                width: size,
                height: size,
                image: NetworkImage(avatarUrl),
                placeholderBuilder: (context) =>
                    SizedBox.fromSize(size: Size.square(size)),
              ),
      );
}
