import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/ui/common/page_end_loading_indicator.dart';
import 'package:hkgalden_flutter/ui/thread/comment_cell.dart';
import 'package:redux/redux.dart';

class ThreadPageViewModel {
  final List<Reply> replies;
  final bool isLoading;
  final bool isInitialLoad;
  final List<String> blockedUserIds;
  final Function() onLoadReplies;

  ThreadPageViewModel({this.replies, this.isLoading, this.isInitialLoad, this.blockedUserIds, this.onLoadReplies});
  
  factory ThreadPageViewModel.create(Store<AppState> store) {
    return ThreadPageViewModel(
      replies: store.state.threadState.thread.replies,
      isLoading: store.state.threadState.threadIsLoading,
      isInitialLoad: store.state.threadState.isInitialLoad,
      blockedUserIds: store.state.sessionUserState.sessionUser.blockedUsers,
      onLoadReplies: () {
        List<Widget> repliesWidgets = [];
        for (Reply reply in store.state.threadState.thread.replies) {
          if (reply.floor % 50 == 1) {
            repliesWidgets.add(Container(
              height: 50,
              child: Center(
                child: Text(reply.floor == 1 ? '第 1 頁' : '第 ${((reply.floor + 49) ~/ 50)} 頁'),
              ),
            ));
          }
          repliesWidgets.add(
            Visibility(
              visible: !store.state.sessionUserState.sessionUser.blockedUsers.contains(reply.author.userId),
              child: CommentCell(reply: reply)
            ),
          );
        }
        repliesWidgets.add((store.state.threadState.thread.totalReplies.toDouble() / 50.0).ceil() > store.state.threadState.currentPage ? 
          PageEndLoadingInidicator(): 
          Container(
            height: 50,
            child: Center(
              child: Text('已到post底', style: TextStyle(color: Colors.grey))
            ),
          )
        );
        return repliesWidgets;
      },
    );
  }
}