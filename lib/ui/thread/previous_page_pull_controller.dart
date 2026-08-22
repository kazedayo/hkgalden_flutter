import 'package:flutter/services.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_cubit.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton_cell.dart';

/// Dart side of the WebView previous-page pull: haptic + load request.
/// Gesture and indicator live in `assets/thread_webview`.
class PreviousPagePullController {
  static const double maxExtent = ThreadPageLoadingSkeletonCell.totalHeight;

  bool loading = false;

  void clear() {
    loading = false;
  }

  void finishLoading() {
    loading = false;
  }

  void handleJsPull({
    required String phase,
    required ThreadCubit threadCubit,
  }) {
    final state = threadCubit.state;
    if (phase == 'arm') {
      if (state is ThreadLoaded && state.currentPage > 1 && !loading) {
        HapticFeedback.mediumImpact();
      }
      return;
    }
    if (phase != 'load' || loading) {
      return;
    }
    if (state is ThreadAppending ||
        state is! ThreadLoaded ||
        state.currentPage <= 1) {
      return;
    }
    loading = true;
    threadCubit.request(
      threadId: state.thread.threadId,
      page: state.currentPage - 1,
      isInitialLoad: false,
    );
  }
}
