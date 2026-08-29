part of '../home_page.dart';

Widget _buildFab(BuildContext context, ThreadListCubit threadListBloc) {
  return galdenFabHero(
    child: FloatingActionButton(
      heroTag: null,
      onPressed: () =>
          BlocProvider.of<SessionUserCubit>(context).state is SessionUserLoaded
              ? showComposeSheet(
                  context: context,
                  builder: (context) => ComposePage(
                    composeMode: ComposeMode.newPost,
                    onCreateThread: (channelId) =>
                        threadListBloc.load(channelId: channelId, page: 1),
                  ),
                )
              : showLoginRequired(context),
      child: const Icon(Icons.create_rounded),
    ),
  );
}
