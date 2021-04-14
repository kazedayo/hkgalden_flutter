part of '../thread_page.dart';

FloatingActionButton _buildFab(
    BuildContext context,
    ScrollController scrollController,
    ThreadLoaded state,
    bool canReply,
    bool onLastPage,
    Function(BuildContext, ScrollController, Reply, bool) onReplySuccess) {
  return FloatingActionButton(
    onPressed: () => !canReply
        ? showCustomDialog(
            context: context,
            builder: (context) => const CustomAlertDialog(
                  title: '未登入',
                  content: '請先登入',
                ))
        : showBarModalBottomSheet(
            duration: const Duration(milliseconds: 300),
            animationCurve: Curves.easeOut,
            context: context,
            builder: (context) => ComposePage(
              composeMode: ComposeMode.reply,
              threadId: state.thread.threadId,
              onSent: (reply) {
                onReplySuccess(context, scrollController, reply, onLastPage);
              },
            ),
          ),
    child: const Icon(Icons.reply_rounded),
  );
}
