import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/ui/thread/skeletons/thread_page_loading_skeleton_cell.dart';

/// Pull-down-to-load-previous-page gesture state for the thread list.
class PreviousPagePullController {
  PreviousPagePullController({required TickerProvider vsync})
      : _snapController = AnimationController(
          vsync: vsync,
          duration: const Duration(milliseconds: 280),
        ) {
    _snapController.addListener(_onSnapTick);
  }

  static const double maxExtent = ThreadPageLoadingSkeletonCell.totalHeight;
  static const double armExtent = maxExtent * 0.80;
  static const double disarmExtent = maxExtent * 0.70;
  static const double dragFactor = 0.85;

  final AnimationController _snapController;
  final ValueNotifier<double> extent = ValueNotifier<double>(0);

  bool armed = false;
  bool loading = false;
  bool fingerDown = false;

  double _snapBegin = 0;
  double _snapEnd = 0;
  int _snapGeneration = 0;

  void _onSnapTick() {
    final t = Curves.easeOutCubic.transform(_snapController.value);
    extent.value = _snapBegin + (_snapEnd - _snapBegin) * t;
  }

  void dispose() {
    _snapController
      ..removeListener(_onSnapTick)
      ..dispose();
    extent.dispose();
  }

  void stopSnapAnimation() {
    if (_snapController.isAnimating) {
      _snapGeneration++;
      _snapController.stop();
    }
  }

  void clear({bool animate = false}) {
    armed = false;
    loading = false;
    fingerDown = false;
    if (animate && extent.value > 0) {
      animateExtentTo(0);
    } else {
      stopSnapAnimation();
      if (extent.value != 0) {
        extent.value = 0;
      }
    }
  }

  void setExtent(double value) {
    final next = value.clamp(0.0, maxExtent);
    if (next != extent.value) {
      extent.value = next;
    }
    if (next >= armExtent) {
      if (!armed) {
        armed = true;
        HapticFeedback.mediumImpact();
      }
    } else if (next < disarmExtent) {
      armed = false;
    }
  }

  void animateExtentTo(double target) {
    stopSnapAnimation();
    final begin = extent.value;
    if ((begin - target).abs() < 0.5) {
      extent.value = target;
      if (target == 0) {
        armed = false;
      }
      return;
    }
    _snapBegin = begin;
    _snapEnd = target;
    final generation = ++_snapGeneration;
    _snapController.forward(from: 0).whenComplete(() {
      if (generation != _snapGeneration) {
        return;
      }
      extent.value = target;
      if (target == 0) {
        armed = false;
      }
    });
  }

  bool isAtScrollTop(ScrollMetrics metrics) => metrics.extentBefore <= 0.5;

  bool onOverscrollIndicator(OverscrollIndicatorNotification notification) {
    if (notification.depth != 0 || !notification.leading) {
      return false;
    }
    if (fingerDown || extent.value > 0) {
      notification.disallowIndicator();
      return true;
    }
    return false;
  }

  /// Handles previous-page pull. Returns false so notifications continue.
  bool onScrollNotification(
    ScrollNotification notification,
    ThreadBloc threadBloc, {
    required VoidCallback onScrollTick,
    required VoidCallback onScrollEndPersist,
  }) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }

    final state = threadBloc.state;

    if (state is ThreadLoaded || state is ThreadAppending) {
      if (notification is ScrollUpdateNotification ||
          notification is ScrollEndNotification) {
        onScrollTick();
      }
      if (notification is ScrollEndNotification && state is ThreadLoaded) {
        onScrollEndPersist();
      }
    }

    if (state is ThreadAppending) {
      return false;
    }
    if (state is! ThreadLoaded || state.currentPage <= 1) {
      if (extent.value > 0 || armed) {
        clear();
      }
      return false;
    }

    if (loading) {
      return false;
    }

    final metrics = notification.metrics;
    if (!metrics.hasContentDimensions) {
      return false;
    }

    final axisDown = metrics.axisDirection == AxisDirection.down ||
        metrics.axisDirection == AxisDirection.right;

    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null && isAtScrollTop(metrics)) {
        fingerDown = true;
        stopSnapAnimation();
      }
    } else if (notification is OverscrollNotification) {
      if (notification.dragDetails == null) {
        return false;
      }
      if (!fingerDown && !isAtScrollTop(metrics)) {
        return false;
      }
      fingerDown = true;
      stopSnapAnimation();
      final delta =
          axisDown ? -notification.overscroll : notification.overscroll;
      if (delta != 0) {
        setExtent(extent.value + delta * dragFactor);
      }
    } else if (notification is ScrollUpdateNotification) {
      final scrollDelta = notification.scrollDelta;
      if (scrollDelta == null || scrollDelta == 0) {
        return false;
      }
      final pulling =
          extent.value > 0 || (fingerDown && isAtScrollTop(metrics));
      if (!pulling) {
        return false;
      }
      if (notification.dragDetails != null) {
        fingerDown = true;
      }
      final delta = axisDown ? -scrollDelta : scrollDelta;
      setExtent(extent.value + delta * dragFactor);
    } else if (notification is ScrollEndNotification) {
      if (fingerDown || extent.value > 0) {
        fingerDown = false;
        handleRelease(threadBloc, state);
      }
    }

    return false;
  }

  void handleRelease(ThreadBloc threadBloc, ThreadLoaded state) {
    if (loading) {
      return;
    }
    if (armed && state.currentPage > 1) {
      armed = false;
      loading = true;
      stopSnapAnimation();
      extent.value = maxExtent;
      threadBloc.add(RequestThreadEvent(
        threadId: state.thread.threadId,
        page: state.currentPage - 1,
        isInitialLoad: false,
      ));
      return;
    }
    armed = false;
    if (extent.value > 0) {
      animateExtentTo(0);
    }
  }

  /// Call when a previous-page request finishes (success path).
  void onThreadLoaded({
    required bool mounted,
    required ScrollController scrollController,
    required bool hasPreviousReplies,
    required void Function(void Function()) schedulePostFrame,
  }) {
    if (!loading && extent.value <= 0) {
      return;
    }
    final wasLoading = loading;
    final preserveGap = wasLoading ? maxExtent : extent.value;
    loading = false;
    armed = false;
    fingerDown = false;
    stopSnapAnimation();
    if (wasLoading && hasPreviousReplies) {
      schedulePostFrame(() {
        if (!mounted || !scrollController.hasClients) {
          return;
        }
        final position = scrollController.position;
        if (position.hasContentDimensions && position.minScrollExtent < 0) {
          final target =
              (-preserveGap).clamp(position.minScrollExtent, 0.0);
          position.jumpTo(target);
        }
        if (extent.value != 0) {
          extent.value = 0;
        }
      });
    } else {
      extent.value = 0;
    }
  }
}
