import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class UserAvatarImage extends StatelessWidget {
  final String avatarUrl;
  final String? groupId;
  final double size;

  const UserAvatarImage({
    super.key,
    required this.avatarUrl,
    this.groupId,
    this.size = 25,
  });

  @override
  Widget build(BuildContext context) {
    final int cacheSize =
        (size * MediaQuery.devicePixelRatioOf(context)).toInt();

    final Widget avatarImage = avatarUrl.isEmpty
        ? SvgPicture.asset(
            'assets/icon-hkgalden.svg',
            width: size,
            height: size,
            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
          )
        : Image(
            width: size,
            height: size,
            image: ResizeImage(
              NetworkImage(avatarUrl),
              width: cacheSize,
              height: cacheSize,
            ),
            gaplessPlayback: true,
            loadingBuilder: (context, child, loading) => loading == null
                ? child
                : SizedBox.fromSize(size: Size.square(size)),
          );

    return Material(
      shape: const CircleBorder(),
      elevation: 6,
      clipBehavior: Clip.hardEdge,
      child: Container(
        width: 50,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          gradient: groupId == null
              ? null
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    if (groupId == 'ADMIN')
                      const Color(0xff7435a0)
                    else
                      const Color(0xffe0561d),
                    if (groupId == 'ADMIN')
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
}
