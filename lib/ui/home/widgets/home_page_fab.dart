part of '../home_page.dart';

FloatingActionButton _buildFab(
    BuildContext context, ThreadListBloc threadListBloc) {
  return FloatingActionButton(
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
            : showCustomDialog(
                context: context,
                builder: (context) => const CustomAlertDialog(
                  title: '未登入',
                  content: '請先登入',
                ),
              ),
    child: const Icon(Icons.create_rounded),
  );
}
