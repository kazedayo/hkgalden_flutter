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
