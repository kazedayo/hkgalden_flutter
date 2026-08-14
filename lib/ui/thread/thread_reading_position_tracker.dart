import 'package:flutter/widgets.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/models/thread_reading_position.dart';
import 'package:hkgalden_flutter/ui/thread/reply_position_anchor.dart';
import 'package:hkgalden_flutter/ui/thread/thread_paint_geometry.dart';
import 'package:hkgalden_flutter/utils/thread_reading_position_store.dart';

/// Caches and persists the reading floor from scroll + reply anchors.
class ThreadReadingPositionTracker {
  ThreadReadingPositionTracker({
    required this.scrollController,
    required this.anchorRegistry,
  });

  final ScrollController scrollController;
  final ReplyAnchorRegistry anchorRegistry;

  int? cachedLastFloor;
  ThreadBloc? threadBloc;

  double? viewportTopY() {
    if (!threadCanReadPaintGeometry() || !scrollController.hasClients) {
      return null;
    }
    final notificationContext =
        scrollController.position.context.notificationContext;
    final box = notificationContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) {
      return null;
    }
    return box.localToGlobal(Offset.zero).dy;
  }

  bool isAtScrollTrailingEdge() {
    if (!scrollController.hasClients) {
      return false;
    }
    final position = scrollController.position;
    if (!position.hasContentDimensions) {
      return false;
    }
    return position.pixels >= position.maxScrollExtent - 1.0;
  }

  void updateCachedFloor({required double safeBottom}) {
    final topY = viewportTopY();
    final atEnd = isAtScrollTrailingEdge();

    int? viewportTopFloor;
    int? lastVisibleFloor;
    if (topY != null) {
      viewportTopFloor = anchorRegistry.readingFloor(viewportTopY: topY);
      if (atEnd && scrollController.hasClients) {
        final bottomY =
            topY + scrollController.position.viewportDimension - safeBottom;
        lastVisibleFloor = anchorRegistry.lastVisibleFloor(
          viewportTopY: topY,
          viewportBottomY: bottomY,
        );
      }
    }

    final state = threadBloc?.state;
    final lastLoadedFloor = state is ThreadLoaded &&
            state.thread.replies.isNotEmpty
        ? state.thread.replies.last.floor
        : null;

    final floor = ThreadReadingPosition.resolveFloorForPersistence(
      viewportTopFloor: viewportTopFloor,
      lastVisibleFloor: lastVisibleFloor,
      lastLoadedFloor: lastLoadedFloor,
      atTrailingEdge: atEnd,
    );
    if (floor != null) {
      cachedLastFloor = floor;
    }
  }

  void persist({required double safeBottom, bool remeasure = true}) {
    final bloc = threadBloc;
    if (bloc == null) {
      return;
    }
    final state = bloc.state;
    if (state is! ThreadLoaded) {
      return;
    }
    if (remeasure && anchorRegistry.hasEntries) {
      updateCachedFloor(safeBottom: safeBottom);
    } else if (isAtScrollTrailingEdge() && state.thread.replies.isNotEmpty) {
      final lastLoaded = state.thread.replies.last.floor;
      final resolved = ThreadReadingPosition.resolveFloorForPersistence(
        viewportTopFloor: cachedLastFloor,
        lastVisibleFloor: null,
        lastLoadedFloor: lastLoaded,
        atTrailingEdge: true,
      );
      if (resolved != null) {
        cachedLastFloor = resolved;
      }
    }
    final resolvedFloor = cachedLastFloor ??
        (state.thread.replies.isNotEmpty
            ? state.thread.replies.last.floor
            : null);
    if (resolvedFloor == null) {
      return;
    }
    cachedLastFloor = resolvedFloor;
    final page = ThreadReadingPosition.pageForFloor(resolvedFloor);
    ThreadReadingPositionStore.instance.save(
      state.thread.threadId,
      page: page,
      floor: resolvedFloor,
    );
  }
}
