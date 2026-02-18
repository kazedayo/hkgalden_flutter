part of '../comment_cell.dart';

class CommentUserInfoCluster extends StatelessWidget {
  const CommentUserInfoCluster({
    super.key,
    required this.reply,
    required this.sessionUserBloc,
  });

  final Reply reply;
  final SessionUserBloc sessionUserBloc;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      top: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => showPopover(
                context: context,
                bodyBuilder: (context) => _CommentUserPopover(
                      reply: reply,
                      sessionUserBloc: sessionUserBloc,
                    ),
                backgroundColor: Colors.black87,
                barrierColor: Colors.transparent,
                width: 150,
                height: 100),
            child: AvatarWidget(
              avatarImage: reply.author.avatar == ''
                  ? SvgPicture.asset('assets/icon-hkgalden.svg',
                      width: 25,
                      height: 25,
                      colorFilter:
                          const ColorFilter.mode(Colors.grey, BlendMode.srcIn))
                  : OctoImage(
                      placeholderBuilder: (context) => SizedBox.fromSize(
                        size: const Size.square(30),
                      ),
                      image: NetworkImage(reply.author.avatar),
                      width: 25,
                      height: 25,
                    ),
              userGroup: reply.author.userGroup,
            ),
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
                reply.authorNickname,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: reply.author.gender == 'M'
                          ? Theme.of(context).colorScheme.brotherColor
                          : Theme.of(context).colorScheme.sisterColor,
                    ),
              ),
              const SizedBox(
                height: 3,
              ),
              Text('#${reply.floor}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          )
        ],
      ),
    );
  }
}

class _CommentUserPopover extends StatelessWidget {
  final Reply reply;
  final SessionUserBloc sessionUserBloc;

  const _CommentUserPopover(
      {required this.reply, required this.sessionUserBloc});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ListTile(
              dense: true,
              leading:
                  const Icon(Icons.account_box_rounded, color: Colors.white),
              title: const Text('會員檔案', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                showMaterialModalBottomSheet(
                    duration: const Duration(milliseconds: 200),
                    animationCurve: Curves.easeOut,
                    backgroundColor: Colors.transparent,
                    barrierColor: Colors.black87,
                    context: context,
                    enableDrag: false,
                    builder: (context) => UserPage(
                          user: reply.author,
                        ));
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(
                Icons.block_outlined,
                color: Colors.redAccent,
              ),
              title: const Text('封鎖會員', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(context).pop();
                sessionUserBloc.state is! SessionUserLoaded
                    ? showCustomDialog(
                        context: context,
                        builder: (context) => const CustomAlertDialog(
                            title: "未登入", content: "請先登入"),
                      )
                    : HKGaldenApi()
                        .blockUser(reply.author.userId)
                        .then((isSuccess) {
                        if (isSuccess!) {
                          sessionUserBloc.add(AppendUserToBlockListEvent(
                              userId: reply.author.userId));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content:
                                    Text('已封鎖會員 ${reply.authorNickname}')));
                          }
                        } else {}
                      });
              },
            ),
          ],
        ),
      );
}
