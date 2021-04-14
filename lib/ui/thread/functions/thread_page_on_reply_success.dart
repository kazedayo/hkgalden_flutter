part of '../thread_page.dart';

void _onReplySuccess(BuildContext context, ScrollController scrollController, Reply reply, bool onLastPage) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('回覆發送成功!')));
    if (onLastPage) {
      BlocProvider.of<ThreadBloc>(context)
          .add(AppendReplyToThreadEvent(reply: reply));
      SchedulerBinding.instance!.addPostFrameCallback((_) {
        scrollController.animateTo(scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
      });
    }
  }