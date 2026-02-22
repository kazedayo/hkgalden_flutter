part of '../home_page.dart';

// ignore: unused_element
class _PopupMenuButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double deviceWidth = MediaQuery.sizeOf(context).width;
    final double deviceHeight = MediaQuery.sizeOf(context).height;
    return PopupMenuButton(
      offset: Offset(deviceWidth, -deviceHeight),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _MenuItem.account,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.account_box_rounded),
            title: Text('個人檔案'),
          ),
        ),
        const PopupMenuItem(
          value: _MenuItem.blocklist,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.block_rounded),
            title: Text('封鎖名單'),
          ),
        ),
        const PopupMenuItem(
          value: _MenuItem.licences,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.copyright_rounded),
            title: Text('版權資訊'),
          ),
        ),
        PopupMenuItem(
          value: _MenuItem.logout,
          child: ListTile(
            dense: true,
            leading: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text('登出'),
          ),
        ),
      ],
      onSelected: (value) async {
        switch (value) {
          case _MenuItem.account:
            showMaterialModalBottomSheet(
              duration: const Duration(milliseconds: 200),
              animationCurve: Curves.easeOut,
              enableDrag: false,
              backgroundColor: Colors.transparent,
              barrierColor: AppTheme.barrierColor,
              context: context,
              builder: (context) => UserPage(
                user: (BlocProvider.of<SessionUserBloc>(context).state
                        as SessionUserLoaded)
                    .sessionUser,
              ),
            );
            break;
          case _MenuItem.blocklist:
            showMaterialModalBottomSheet(
              duration: const Duration(milliseconds: 200),
              animationCurve: Curves.easeOut,
              enableDrag: false,
              backgroundColor: Colors.transparent,
              barrierColor: AppTheme.barrierColor,
              context: context,
              builder: (context) => BlockListPage(),
            );
            break;
          case _MenuItem.licences:
            final PackageInfo info = await PackageInfo.fromPlatform();
            if (!context.mounted) return;
            showLicensePage(
              context: context,
              applicationName: 'hkGalden',
              applicationIcon: SvgPicture.asset('assets/icon-hkgalden.svg',
                  width: 50,
                  height: 50,
                  colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.secondary,
                      BlendMode.srcIn)),
              applicationVersion: '${info.version}+${info.buildNumber}',
              applicationLegalese: '© hkGalden & 1080',
            );
            break;
          case _MenuItem.logout:
            await TokenStore().writeToken('');
            if (!context.mounted) return;
            BlocProvider.of<SessionUserBloc>(context)
                .add(RemoveSessionUserEvent());
            BlocProvider.of<ThreadListBloc>(context).add(
              RequestThreadListEvent(
                  channelId: (BlocProvider.of<ChannelBloc>(context).state
                          as ChannelLoaded)
                      .selectedChannelId,
                  page: 1,
                  isRefresh: false),
            );
        }
      },
      icon: const Icon(Icons.apps_rounded),
    );
  }
}

enum _MenuItem { account, blocklist, licences, logout }
