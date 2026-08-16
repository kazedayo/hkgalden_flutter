part of '../home_page.dart';

Widget _buildFab(BuildContext context, ThreadListBloc threadListBloc) {
  return galdenFabHero(
    child: FloatingActionButton(
      heroTag: null,
      onPressed: () =>
          BlocProvider.of<SessionUserBloc>(context).state is SessionUserLoaded
              ? showBarModalBottomSheet(
                  duration: const Duration(milliseconds: 300),
                  animationCurve: Curves.easeOut,
                  context: context,
                  builder: (context) => ComposePage(
                    composeMode: ComposeMode.newPost,
                    onCreateThread: (channelId) => threadListBloc.add(
                      RequestThreadListEvent(
                          channelId: channelId, page: 1, isRefresh: false),
                    ),
                  ),
                )
              : showCustomAlert(
                  context: context,
                  title: '未登入',
                  content: '請先登入',
                ),
      child: const Icon(Icons.create_rounded),
    ),
  );
}
