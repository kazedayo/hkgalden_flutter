/// Last-read location within a thread (page + floor / reply #).
class ThreadReadingPosition {
  /// 1-based page number (50 floors per page).
  final int page;

  /// 1-based floor / reply number within the thread.
  final int floor;

  /// Epoch ms when this position was last updated.
  final int updatedAtMs;

  const ThreadReadingPosition({
    required this.page,
    required this.floor,
    required this.updatedAtMs,
  });

  /// Page that contains [floor] (floors 1–50 → page 1, etc.).
  static int pageForFloor(int floor) {
    if (floor < 1) {
      return 1;
    }
    return ((floor - 1) ~/ 50) + 1;
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
