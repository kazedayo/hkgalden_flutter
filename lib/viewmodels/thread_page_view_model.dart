import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/ui/thread/comment_cell.dart';
import 'package:redux/redux.dart';

class ThreadPageViewModel {
  final List<Reply> replies;
  final bool isLoading;
  final List<String> blockedUserIds;
  final Function() onLoadReplies;

  ThreadPageViewModel({this.replies, this.isLoading, this.blockedUserIds, this.onLoadReplies});
  
  factory ThreadPageViewModel.create(Store<AppState> store) {
    return ThreadPageViewModel(
      replies: store.state.threadState.thread.replies,
      isLoading: store.state.threadState.threadIsLoading,
      blockedUserIds: store.state.sessionUserState.sessionUser.blockedUsers,
      onLoadReplies: () {
        List<Widget> repliesWidgets = [];
        for (Reply reply in store.state.threadState.thread.replies) {
          if (reply.floor % 50 == 1) {
            repliesWidgets.add(Container(
              height: 50,
              child: Center(
                child: Text(reply.floor == 1 ? '第 1 頁' : '第 ${(reply.floor + 49) / 50} 頁'),
              ),
            ));
          }
          store.state.sessionUserState.sessionUser.blockedUsers.contains(reply.author.userId) ? 
            repliesWidgets.add(SizedBox()) : 
            repliesWidgets.add(CommentCell(reply: reply));
        }
        return repliesWidgets;
      }
    );
  }
}