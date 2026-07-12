part of '../thread_page.dart';

/// Shared with the home FAB so the iOS Cupertino push/pop keeps a continuous
/// hero flight in the corner.
const Object _kFabHeroTag = 'hkgalden_fab';

FloatingActionButton _buildFab(
  BuildContext context,
  ScrollController scrollController,
  ThreadPageArguments arguments,
  Function(BuildContext, ScrollController, Reply, bool) onReplySuccess,
) {
  return FloatingActionButton(
    heroTag: _kFabHeroTag,
    onPressed: () => !BlocProvider.of<ThreadPageCubit>(context).state.canReply
        ? showCustomAlert(
            context: context,
            title: '未登入',
            content: '請先登入',
          )
        : showBarModalBottomSheet(
            duration: const Duration(milliseconds: 300),
            animationCurve: Curves.easeOut,
            context: context,
            builder: (context) => ComposePage(
              composeMode: ComposeMode.reply,
              threadId: arguments.threadId,
              onSent: (reply) {
                onReplySuccess(
                  context,
                  scrollController,
                  reply,
                  BlocProvider.of<ThreadPageCubit>(context).state.onLastPage,
                );
              },
            ),
          ),
    child: const Icon(Icons.reply_rounded),
  );
}
