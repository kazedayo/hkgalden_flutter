import 'package:flutter/material.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';

class ThreadPageViewModel {
  final List<Reply> replies;
  final bool isLoading;
  final List<String> blockedUserIds;

  ThreadPageViewModel({this.replies, this.isLoading, this.blockedUserIds});
  
  factory ThreadPageViewModel.create(Store<AppState> store) {
    return ThreadPageViewModel(
      replies: store.state.threadState.thread.replies,
      isLoading: store.state.threadState.threadIsLoading,
      blockedUserIds: store.state.sessionUserState.sessionUser.blockedUsers,
    );
  }
}