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
    return ((floor - 1) ~/ 50) + 1;
  }

  /// Floor to persist for reopen.
  ///
  /// Mid-list uses [viewportTopFloor] so restore matches what was at the top of
  /// the screen. At the trailing edge a short final page often cannot reach the
  /// viewport top (earlier floors still fill it) — take the furthest candidate
  /// so page n+1 with one reply is not remembered as page n.
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
