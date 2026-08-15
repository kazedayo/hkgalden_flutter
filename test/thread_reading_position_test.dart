import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hkgalden_flutter/models/thread_reading_position.dart';
import 'package:hkgalden_flutter/utils/thread_reading_position_store.dart';
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

  group('ThreadReadingPosition.resolveFloorForPersistence', () {
    test('mid-list prefers viewport top floor', () {
      expect(
        ThreadReadingPosition.resolveFloorForPersistence(
          viewportTopFloor: 40,
          lastVisibleFloor: 51,
          lastLoadedFloor: 51,
          atTrailingEdge: false,
        ),
        40,
      );
    });

    test('trailing edge takes furthest floor so short final page is kept', () {
      // Page n content still at viewport top; only one reply on page n+1 at end.
      expect(
        ThreadReadingPosition.resolveFloorForPersistence(
          viewportTopFloor: 40,
          lastVisibleFloor: 51,
          lastLoadedFloor: 51,
          atTrailingEdge: true,
        ),
        51,
      );
    });

    test('trailing edge falls back to last loaded when nothing is visible', () {
      expect(
        ThreadReadingPosition.resolveFloorForPersistence(
          viewportTopFloor: 40,
          lastVisibleFloor: null,
          lastLoadedFloor: 51,
          atTrailingEdge: true,
        ),
        51,
      );
    });

    test('trailing edge keeps top floor when it is already furthest', () {
      expect(
        ThreadReadingPosition.resolveFloorForPersistence(
          viewportTopFloor: 51,
          lastVisibleFloor: 51,
          lastLoadedFloor: 51,
          atTrailingEdge: true,
        ),
        51,
      );
    });

    test('returns null when no candidates', () {
      expect(
        ThreadReadingPosition.resolveFloorForPersistence(
          viewportTopFloor: null,
          lastVisibleFloor: null,
          lastLoadedFloor: null,
          atTrailingEdge: true,
        ),
        isNull,
      );
    });
  });

  group('ThreadReadingPositionStore.save', () {
    late Directory tempDir;
    late Duration originalDebounce;

    Future<void> flushHive() =>
        Future<void>.delayed(const Duration(milliseconds: 20));

    setUp(() async {
      originalDebounce = ThreadReadingPositionStore.persistDebounce;
      ThreadReadingPositionStore.persistDebounce = Duration.zero;
      ThreadReadingPositionStore.instance.resetForTest();
      tempDir = await Directory.systemTemp.createTemp('thread_reading_pos_');
      Hive.init(tempDir.path);
      await Hive.openBox(ThreadReadingPositionStore.boxName);
    });

    tearDown(() async {
      ThreadReadingPositionStore.instance.resetForTest();
      ThreadReadingPositionStore.persistDebounce = originalDebounce;
      if (Hive.isBoxOpen(ThreadReadingPositionStore.boxName)) {
        await Hive.box(ThreadReadingPositionStore.boxName).close();
      }
      await Hive.deleteBoxFromDisk(ThreadReadingPositionStore.boxName);
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('get returns latest in-memory value before Hive write', () async {
      final store = ThreadReadingPositionStore.instance;
      ThreadReadingPositionStore.persistDebounce = const Duration(seconds: 1);

      await store.save(42, page: 2, floor: 60);
      expect(store.get(42)?.page, 2);
      expect(store.get(42)?.floor, 60);
      expect(Hive.box(ThreadReadingPositionStore.boxName).get('42'), isNull);
    });

    test('skips Hive rewrite when page and floor are unchanged', () async {
      final store = ThreadReadingPositionStore.instance;
      await store.save(7, page: 1, floor: 12);
      await flushHive();
      final first = Map<String, dynamic>.from(
        Hive.box(ThreadReadingPositionStore.boxName).get('7') as Map,
      );

      await store.save(7, page: 1, floor: 12);
      await flushHive();
      final second = Map<String, dynamic>.from(
        Hive.box(ThreadReadingPositionStore.boxName).get('7') as Map,
      );

      expect(second['updatedAtMs'], first['updatedAtMs']);
      expect(second['page'], 1);
      expect(second['floor'], 12);
    });

    test('last write wins when floor changes before debounce', () async {
      final store = ThreadReadingPositionStore.instance;
      ThreadReadingPositionStore.persistDebounce =
          const Duration(milliseconds: 30);

      await store.save(9, page: 1, floor: 3);
      await store.save(9, page: 1, floor: 8);
      expect(store.get(9)?.floor, 8);
      expect(Hive.box(ThreadReadingPositionStore.boxName).get('9'), isNull);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      final raw = Hive.box(ThreadReadingPositionStore.boxName).get('9') as Map;
      expect(raw['floor'], 8);
      expect(raw['page'], 1);
    });
  });
}
