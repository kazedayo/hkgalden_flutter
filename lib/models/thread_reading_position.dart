/// Floors per page. Keep in sync with assets/thread_webview/render.js (~line 131).
const int kRepliesPerPage = 50;

class ThreadReadingPosition {
  final int page;

  final int floor;

  final int updatedAtMs;

  const ThreadReadingPosition({
    required this.page,
    required this.floor,
    required this.updatedAtMs,
  });

  static int pageForFloor(int floor) {
    if (floor < 1) {
      return 1;
    }
    return ((floor - 1) ~/ kRepliesPerPage) + 1;
  }

  /// Page count for [totalReplies] replies (≥1: every thread has the OP page).
  /// Equals `pageForFloor` since floors are 1-based and dense.
  static int pageCountFor(int totalReplies) => pageForFloor(totalReplies);

  /// Mid-list: viewport top. Trailing edge: furthest visible/loaded floor.
  static int? resolveFloorForPersistence({
    required int? viewportTopFloor,
    required int? lastVisibleFloor,
    required int? lastLoadedFloor,
    required bool atTrailingEdge,
  }) {
    if (atTrailingEdge) {
      var best = viewportTopFloor;
      for (final candidate in [lastVisibleFloor, lastLoadedFloor]) {
        if (candidate == null) {
          continue;
        }
        if (best == null || candidate > best) {
          best = candidate;
        }
      }
      return best;
    }
    return viewportTopFloor ?? lastVisibleFloor;
  }

  factory ThreadReadingPosition.fromMap(Map<dynamic, dynamic> map) {
    final floor = (map['floor'] as num?)?.toInt() ?? 1;
    final page = (map['page'] as num?)?.toInt() ?? pageForFloor(floor);
    final updatedAtMs = (map['updatedAtMs'] as num?)?.toInt() ?? 0;
    return ThreadReadingPosition(
      page: page < 1 ? 1 : page,
      floor: floor < 1 ? 1 : floor,
      updatedAtMs: updatedAtMs,
    );
  }

  Map<String, dynamic> toMap() => {
        'page': page,
        'floor': floor,
        'updatedAtMs': updatedAtMs,
      };

  @override
  String toString() =>
      'ThreadReadingPosition(page: $page, floor: $floor, updatedAtMs: $updatedAtMs)';
}
