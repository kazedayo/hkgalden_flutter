import 'package:hkgalden_flutter/models/thread_reading_position.dart';
import 'package:test/test.dart';

void main() {
  group('ThreadReadingPosition.pageForFloor', () {
    test('maps floors to 50-floor pages', () {
      expect(ThreadReadingPosition.pageForFloor(1), 1);
      expect(ThreadReadingPosition.pageForFloor(50), 1);
      expect(ThreadReadingPosition.pageForFloor(51), 2);
      expect(ThreadReadingPosition.pageForFloor(100), 2);
      expect(ThreadReadingPosition.pageForFloor(101), 3);
    });

    test('clamps invalid floors to page 1', () {
      expect(ThreadReadingPosition.pageForFloor(0), 1);
      expect(ThreadReadingPosition.pageForFloor(-5), 1);
    });
  });

  group('ThreadReadingPosition serialization', () {
    test('round-trips through map', () {
      const original = ThreadReadingPosition(
        page: 3,
        floor: 120,
        updatedAtMs: 1234567890,
      );
      final restored = ThreadReadingPosition.fromMap(original.toMap());
      expect(restored.page, original.page);
      expect(restored.floor, original.floor);
      expect(restored.updatedAtMs, original.updatedAtMs);
    });

    test('derives page from floor when page missing', () {
      final restored = ThreadReadingPosition.fromMap({
        'floor': 75,
        'updatedAtMs': 1,
      });
      expect(restored.floor, 75);
      expect(restored.page, 2);
    });
  });
}
