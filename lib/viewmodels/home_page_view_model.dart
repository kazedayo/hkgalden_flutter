import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/ui/common/page_end_loading_indicator.dart';
import 'package:hkgalden_flutter/ui/home/thread_cell.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page.dart';
import 'package:redux/redux.dart';
import 'package:hkgalden_flutter/redux/thread_list/thread_list_action.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';

class HomePageViewModel {
  final List<Thread> threads;
  final String title;
  final String selectedChannelId;
  final bool isThreadLoading;
  final bool isRefresh;
  final Function(String) onRefresh;
  final Function(BuildContext) onLoadThreadList;

  HomePageViewModel({
    this.threads,
    this.title,
    this.selectedChannelId,
    this.isThreadLoading,
    this.isRefresh,
    this.onRefresh,
    this.onLoadThreadList,
  });

  factory HomePageViewModel.create(Store<AppState> store) {
    return HomePageViewModel(
      threads: store.state.threadListState.threads,
      title: store.state.channelState.channels.where(
        (channel) => channel.channelId == store.state.channelState.selectedChannelId)
      .first.channelName,
      selectedChannelId: store.state.channelState.selectedChannelId,
      isThreadLoading: store.state.threadListState.threadListIsLoading,
      isRefresh: store.state.threadListState.isRefresh,
      onRefresh: (channelId) => store.dispatch(RequestThreadListAction(channelId: channelId, page: 1,isRefresh: true)),
      onLoadThreadList: (BuildContext context) {
        List<Widget> threadCells = [];
        for (Thread thread in store.state.threadListState.threads)
          threadCells.add(ThreadCell(
            title: thread.title,
            authorName: thread.replies[0].authorNickname,
            totalReplies: thread.totalReplies,
            lastReply: thread.replies.length == 2 ? 
                        thread.replies[1].date : 
                        thread.replies[0].date,
            onTap: () {
              store.dispatch(RequestThreadAction(threadId: thread.threadId, page: 1, isInitialLoad: true));
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => ThreadPage(
                title: thread.title,
                threadId: thread.threadId,
              )));
            },
          ));
        threadCells.add(PageEndLoadingInidicator());
        return threadCells;
      }
    );
  }
}