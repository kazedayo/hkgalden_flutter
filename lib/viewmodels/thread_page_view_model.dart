import 'package:equatable/equatable.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/redux/app/app_state.dart';
import 'package:hkgalden_flutter/redux/thread/thread_action.dart';
import 'package:redux/redux.dart';

class ThreadPageViewModel extends Equatable {
  final int threadId;
  final List<Reply> previousPageReplies;
  final List<Reply> replies;
  final bool isLoading;
  final bool isInitialLoad;
  final List<String> blockedUserIds;
  final int totalReplies;
  final int currentPage;
  final int endPage;
  final String status;
  final Function(Reply) appendReply;

  ThreadPageViewModel({
    this.threadId,
    this.previousPageReplies,
    this.replies,
    this.isLoading,
    this.isInitialLoad,
    this.blockedUserIds,
    this.totalReplies,
    this.currentPage,
    this.endPage,
    this.status,
    this.appendReply,
  });

  factory ThreadPageViewModel.create(Store<AppState> store) {
    return ThreadPageViewModel(
        threadId: store.state.threadState.thread.threadId,
        previousPageReplies: store.state.threadState.previousPages.replies
            .where((reply) => !store
                .state.sessionUserState.sessionUser.blockedUsers
                .contains(reply.author.userId))
            .toList(),
        replies: store.state.threadState.thread.replies
            .where((reply) => !store
                .state.sessionUserState.sessionUser.blockedUsers
                .contains(reply.author.userId))
            .toList(),
        isLoading: store.state.threadState.threadIsLoading,
        isInitialLoad: store.state.threadState.isInitialLoad,
        blockedUserIds: store.state.sessionUserState.sessionUser.blockedUsers,
        totalReplies: store.state.threadState.thread.totalReplies,
        currentPage: store.state.threadState.currentPage,
        endPage: store.state.threadState.endPage,
        status: store.state.threadState.thread.status,
        appendReply: (reply) =>
            store.dispatch(AppendReplyToThreadAction(reply: reply)));
  }

  List<Object> get props => [
        threadId,
        previousPageReplies,
        replies,
        isLoading,
        isInitialLoad,
        blockedUserIds,
        totalReplies,
        currentPage,
        status,
        endPage
      ];
}
