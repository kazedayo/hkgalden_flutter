import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_scroll_controller.dart';

/// Center-pin / trailing-edge restore settle for thread open.
class ThreadRestoreController {
  ThreadRestoreController();

  static const Duration settleDuration = Duration(milliseconds: 1500);
  static const Duration revealTimeout = Duration(milliseconds: 220);

  final ValueNotifier<double> trailingTopPad = ValueNotifier<double>(0);
  final ValueNotifier<bool> visualReady = ValueNotifier<bool>(true);

  bool didPinInitialCenter = false;
  bool pendingRestoreToTrailingEdge = false;
  bool trailingEdgeLayoutActive = false;
  bool settling = false;

  int? pendingRestoreFloor;
  int? centerAnchorFloor;
  bool didResolveCenterAnchor = false;

  int _settleGeneration = 0;
  int _stableFrames = 0;
  double? _stabilityPad;
  double? _stabilityPixels;
  bool _revealTimeoutScheduled = false;

  void dispose() {
    cancelSettle();
    trailingTopPad.dispose();
    visualReady.dispose();
  }

  void captureArgsFloor(int? floor) {
    pendingRestoreFloor = floor;
    if (floor != null) {
      visualReady.value = false;
    }
  }

  void cancelSettle() {
    settling = false;
    _settleGeneration++;
    trailingEdgeLayoutActive = false;
    revealContent();
  }

  void revealContent() {
    if (visualReady.value) {
      return;
    }
    visualReady.value = true;
  }

  void notePinApplied(ThreadPageScrollController scrollController) {
    if (visualReady.value || !scrollController.hasClients) {
      return;
    }
    final position = scrollController.position;
    if (!position.hasContentDimensions) {
      return;
    }

    final pad = trailingTopPad.value;
    final pixels = position.pixels;
    final padStable =
        _stabilityPad != null && (pad - _stabilityPad!).abs() <= 0.5;
    final pixelsStable = _stabilityPixels != null &&
        (pixels - _stabilityPixels!).abs() <= 0.5;
    if (padStable && pixelsStable) {
      _stableFrames++;
    } else {
      _stableFrames = 0;
    }
    _stabilityPad = pad;
    _stabilityPixels = pixels;

    if (_stableFrames >= 2) {
      revealContent();
      return;
    }

    if (!_revealTimeoutScheduled) {
      _revealTimeoutScheduled = true;
      Future<void>.delayed(revealTimeout, () {
        revealContent();
      });
    }
  }

  void setTrailingTopPad(
    double nextPad, {
    required bool mounted,
  }) {
    if ((nextPad - trailingTopPad.value).abs() <= 0.5) {
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !trailingEdgeLayoutActive) {
        return;
      }
      if ((nextPad - trailingTopPad.value).abs() <= 0.5) {
        return;
      }
      trailingTopPad.value = nextPad;
    });
  }

  void syncTrailingEdgeLayout({
    required bool mounted,
    required ThreadPageScrollController scrollController,
    required double? Function() footerBottomY,
    required double? Function() viewportTopY,
    required double safeBottom,
  }) {
    if (!trailingEdgeLayoutActive || !pendingRestoreToTrailingEdge) {
      return;
    }
    if (!scrollController.hasClients) {
      return;
    }
    final position = scrollController.position;
    if (!position.hasContentDimensions) {
      return;
    }

    final threshold = visualReady.value ? 1.5 : 0.5;
    final layoutHeight =
        (position.viewportDimension - safeBottom).clamp(0.0, double.infinity);

    final topY = viewportTopY();
    final footerBottom = footerBottomY();

    if (topY != null && footerBottom != null) {
      final layoutBottom = topY + position.viewportDimension - safeBottom;
      final shortfall = layoutBottom - footerBottom;

      if (shortfall > threshold) {
        final nextPad =
            (trailingTopPad.value + shortfall).clamp(0.0, layoutHeight);
        if ((nextPad - trailingTopPad.value).abs() > threshold) {
          setTrailingTopPad(nextPad, mounted: mounted);
          return;
        }
      } else if (shortfall < -threshold) {
        if (trailingTopPad.value > threshold) {
          final nextPad =
              (trailingTopPad.value + shortfall).clamp(0.0, layoutHeight);
          if ((nextPad - trailingTopPad.value).abs() > threshold) {
            setTrailingTopPad(nextPad, mounted: mounted);
            return;
          }
        }
      }
    }

    if ((position.pixels - position.maxScrollExtent).abs() > threshold) {
      scrollController.jumpTo(position.maxScrollExtent);
    }
  }

  void applyPin({
    required bool trailingEdge,
    required bool mounted,
    required ThreadPageScrollController scrollController,
    required double? Function() footerBottomY,
    required double? Function() viewportTopY,
    required double safeBottom,
  }) {
    if (!scrollController.hasClients) {
      return;
    }
    final position = scrollController.position;
    if (!position.hasContentDimensions) {
      return;
    }
    if (trailingEdge) {
      syncTrailingEdgeLayout(
        mounted: mounted,
        scrollController: scrollController,
        footerBottomY: footerBottomY,
        viewportTopY: viewportTopY,
        safeBottom: safeBottom,
      );
    } else if (position.pixels != 0) {
      scrollController.holdCenterAtZero = true;
      try {
        scrollController.jumpTo(0);
      } finally {
        scrollController.holdCenterAtZero = false;
      }
    }
    notePinApplied(scrollController);
  }

  void startSettle({
    required bool trailingEdge,
    required bool mounted,
    required ThreadPageScrollController scrollController,
    required double? Function() footerBottomY,
    required double? Function() viewportTopY,
    required double Function() safeBottom,
  }) {
    settling = true;
    if (trailingEdge) {
      trailingEdgeLayoutActive = true;
    }
    final gen = ++_settleGeneration;
    final deadline = DateTime.now().add(settleDuration);

    void tick() {
      if (!mounted || gen != _settleGeneration || !settling) {
        return;
      }
      applyPin(
        trailingEdge: trailingEdge,
        mounted: mounted,
        scrollController: scrollController,
        footerBottomY: footerBottomY,
        viewportTopY: viewportTopY,
        safeBottom: safeBottom(),
      );
      if (DateTime.now().isBefore(deadline)) {
        SchedulerBinding.instance.addPostFrameCallback((_) => tick());
      } else {
        settling = false;
        revealContent();
      }
    }

    SchedulerBinding.instance.addPostFrameCallback((_) => tick());
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
      pendingRestoreToTrailingEdge = true;
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
    if (pendingRestoreToTrailingEdge) {
      return replies.last.floor;
    }
    return centerAnchorFloor ?? replies.first.floor;
  }
}
