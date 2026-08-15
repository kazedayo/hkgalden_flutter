import 'package:flutter/services.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton_cell.dart';

/// Dart side of the WebView previous-page pull: haptic + load request.
/// Gesture and indicator live in `assets/thread_webview`.
class PreviousPagePullController {
  static const double maxExtent = ThreadPageLoadingSkeletonCell.totalHeight;

  bool loading = false;

  void dispose() {}

  void clear() {
    loading = false;
  }

  void finishLoading() {
    loading = false;
  }

  void handleJsPull({
    required String phase,
    required ThreadBloc threadBloc,
  }) {
    final state = threadBloc.state;
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
    threadBloc.add(RequestThreadEvent(
      threadId: state.thread.threadId,
      page: state.currentPage - 1,
      isInitialLoad: false,
    ));
  }
}
