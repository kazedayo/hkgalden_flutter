part of '../home_page.dart';

PreferredSize _buildAppBar() {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: BlocBuilder<SessionUserBloc, SessionUserState>(
      builder: (context, state) => AppBar(
        leading: _LeadingButton(),
        title: BlocBuilder<ChannelBloc, ChannelState>(
          builder: (context, channelState) {
            if (channelState is! ChannelLoaded) {
              return const SizedBox.shrink();
            }
            final match = channelState.channels.where(
                (channel) => channel.channelId == channelState.selectedChannelId);
            final channelName =
                match.isEmpty ? '' : match.first.channelName;
            return Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Hero(
                      tag: 'logo',
                      child: SvgPicture.asset(
                        'assets/icon-hkgalden.svg',
                        width: 27,
                        height: 27,
                      ),
                    ),
                  ),
                  const WidgetSpan(
                    child: SizedBox(
                      width: 5,
                    ),
                  ),
                  TextSpan(
                    text: channelName,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          if (state is SessionUserLoaded)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _PopupMenuButton(),
            )
          else
            IconButton(
              icon: const Icon(Icons.login_rounded),
              onPressed: () async {
                final result = await FlutterWebAuth2.authenticate(
                    url:
                        "https://hkgalden.org/oauth/v1/authorize?client_id=${HKGaldenApi.clientId}",
                    callbackUrlScheme: "http.hkgalden.app");

                final token = Uri.parse(result).queryParameters['token'];
                await Hive.box('token').put('token', token!);
                if (!context.mounted) return;
                BlocProvider.of<SessionUserBloc>(context)
                    .add(RequestSessionUserEvent());
                context.read<SmileyPackRepository>().prewarm();
                final channelState =
                    BlocProvider.of<ChannelBloc>(context).state;
                if (channelState is ChannelLoaded) {
                  BlocProvider.of<ThreadListBloc>(context).add(
                    RequestThreadListEvent(
                        channelId: channelState.selectedChannelId,
                        page: 1,
                        isRefresh: false),
                  );
                }
              },
            ),
        ],
      ),
    ),
  );
}

class _LeadingButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => IconButton(
        icon: AnimatedIcon(
          icon: AnimatedIcons.close_menu,
          progress: Backdrop.of(context).animationController.view,
        ),
        onPressed: () => Backdrop.of(context).fling(),
      );
}
