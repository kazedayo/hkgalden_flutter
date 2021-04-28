part of '../home_page.dart';

PreferredSize _buildAppBar() {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: BlocBuilder<SessionUserBloc, SessionUserState>(
      builder: (context, state) => AppBar(
        leading: _LeadingButton(),
        title: BlocBuilder<ChannelBloc, ChannelState>(
          builder: (context, state) => Text.rich(
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
                  text: (state as ChannelLoaded)
                      .channels
                      .where((channel) =>
                          channel.channelId == state.selectedChannelId)
                      .first
                      .channelName,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
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
                final result = await FlutterWebAuth.authenticate(
                    url:
                        "https://hkgalden.org/oauth/v1/authorize?client_id=${HKGaldenApi.clientId}",
                    callbackUrlScheme: "http.hkgalden.app");

                final token = Uri.parse(result).queryParameters['token'];
                await TokenStore().writeToken(token!);
                BlocProvider.of<SessionUserBloc>(context)
                    .add(RequestSessionUserEvent());
                BlocProvider.of<ThreadListBloc>(context).add(
                  RequestThreadListEvent(
                      channelId: (BlocProvider.of<ChannelBloc>(context).state
                              as ChannelLoaded)
                          .selectedChannelId,
                      page: 1,
                      isRefresh: false),
                );
              },
            ),
        ],
      ),
    ),
  );
}
