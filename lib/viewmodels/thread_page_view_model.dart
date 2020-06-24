import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:redux/redux.dart';

class ThreadPageViewModel {
  final List<Reply> replies;
  final bool isLoading;
  final bool isInitialLoad;
  final List<String> blockedUserIds;
  final int totalReplies;
  final int currentPage;

  ThreadPageViewModel({
    this.replies, 
    this.isLoading, 
    this.isInitialLoad, 
    this.blockedUserIds, 
    this.totalReplies, 
    this.currentPage
  });
  
  factory ThreadPageViewModel.create(Store<AppState> store) {
    return ThreadPageViewModel(
      replies: store.state.threadState.thread.replies,
      isLoading: store.state.threadState.threadIsLoading,
      isInitialLoad: store.state.threadState.isInitialLoad,
      blockedUserIds: store.state.sessionUserState.sessionUser.blockedUsers,
      totalReplies: store.state.threadState.thread.totalReplies,
      currentPage: store.state.threadState.currentPage,
    );
  }
}