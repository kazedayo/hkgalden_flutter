import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_scroll_controller.dart';

/// Center-pin restore for thread open.
class ThreadRestoreController {
  ThreadRestoreController();

  bool didPinInitialCenter = false;

  int? pendingRestoreFloor;
  int? centerAnchorFloor;
  bool didResolveCenterAnchor = false;

  void captureArgsFloor(int? floor) {
    pendingRestoreFloor = floor;
  }

  void pinCenterIfNeeded(ThreadPageScrollController scrollController) {
    if (!scrollController.hasClients) {
      return;
    }
    final position = scrollController.position;
    if (!position.hasContentDimensions || position.pixels == 0) {
      return;
    }
    scrollController.holdCenterAtZero = true;
    try {
      scrollController.jumpTo(0);
    } finally {
      scrollController.holdCenterAtZero = false;
    }
  }

  void resolveCenterAnchorIfNeeded(ThreadLoaded state) {
    if (didResolveCenterAnchor) {
      return;
    }
    didResolveCenterAnchor = true;
    final requested = pendingRestoreFloor;
    final replies = state.thread.replies;
    if (requested == null || requested < 1 || replies.isEmpty) {
      return;
    }
    final lastFloor = replies.last.floor;
    if (requested >= lastFloor) {
      centerAnchorFloor = lastFloor;
      return;
    }
    final idx = replies.indexWhere((r) => r.floor >= requested);
    if (idx > 0) {
      centerAnchorFloor = replies[idx].floor;
    }
  }

  int centerStartIndex(List<Reply> replies) {
    final anchor = centerAnchorFloor;
    if (anchor == null || replies.isEmpty) {
      return 0;
    }
    final idx = replies.indexWhere((r) => r.floor >= anchor);
    if (idx > 0) {
      return idx;
    }
    if (idx < 0 && replies.length > 1) {
      return replies.length - 1;
    }
    return 0;
  }

  /// Returns the floor to seed into the reading-position cache when resolving.
  int? seedCachedFloor(ThreadLoaded state) {
    final replies = state.thread.replies;
    if (replies.isEmpty) {
      return null;
    }
    return centerAnchorFloor ?? replies.first.floor;
  }
}
