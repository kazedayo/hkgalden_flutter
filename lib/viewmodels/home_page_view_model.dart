import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page.dart';
import 'package:redux/redux.dart';
import 'package:hkgalden_flutter/redux/thread_list/thread_list_action.dart';

class HomePageViewModel {
  final List<Thread> threads;
  final String title;
  final String selectedChannelId;
  final bool isThreadLoading;
  final bool isRefresh;
  final Function(String) onRefresh;
  final List<String> blockedUserIds;
  final Function(BuildContext, Thread) loadThread;
  final Function(BuildContext, Thread) jumpToPage;

  HomePageViewModel({
    this.threads,
    this.title,
    this.selectedChannelId,
    this.isThreadLoading,
    this.isRefresh,
    this.onRefresh,
    this.blockedUserIds,
    this.loadThread,
    this.jumpToPage,
  });

  factory HomePageViewModel.create(Store<AppState> store) {
    return HomePageViewModel(
      threads: store.state.threadListState.threads,
      title: store.state.channelState.channels
          .where((channel) =>
              channel.channelId == store.state.channelState.selectedChannelId)
          .first
          .channelName,
      selectedChannelId: store.state.channelState.selectedChannelId,
      isThreadLoading: store.state.threadListState.threadListIsLoading,
      isRefresh: store.state.threadListState.isRefresh,
      onRefresh: (channelId) => store.dispatch(RequestThreadListAction(
          channelId: channelId, page: 1, isRefresh: true)),
      blockedUserIds: store.state.sessionUserState.sessionUser.blockedUsers,
      loadThread: (context, thread) {
        store.dispatch(RequestThreadAction(
            threadId: thread.threadId, page: 1, isInitialLoad: true));
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ThreadPage(
                  title: thread.title,
                  threadId: thread.threadId,
                )));
      },
      jumpToPage: (context, thread) {
        showModal<void>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('跳到頁數'),
            children: List.generate(
              (thread.replies.last.floor.toDouble() / 50.0).ceil(),
              (index) => SimpleDialogOption(
                    onPressed: () {
                      store.dispatch(RequestThreadAction(
                          threadId: thread.threadId,
                          page: index + 1,
                          isInitialLoad: true));
                      Navigator.of(context).pop();
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => ThreadPage(
                                title: thread.title,
                                threadId: thread.threadId,
                              )));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('第 ${index + 1} 頁'),
                    ),
                  )
                ),
          ),
        );
      },
    );
  }
}
