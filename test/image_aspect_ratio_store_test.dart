import 'dart:io';

import 'package:hive/hive.dart';
import 'package:hkgalden_flutter/utils/image_aspect_ratio_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageAspectRatioStore.isValidAspectRatio', () {
    test('accepts positive finite ratios', () {
      expect(ImageAspectRatioStore.isValidAspectRatio(0.75), isTrue);
      expect(ImageAspectRatioStore.isValidAspectRatio(1), isTrue);
      expect(ImageAspectRatioStore.isValidAspectRatio(2.5), isTrue);
    });

    test('rejects non-positive and non-finite ratios', () {
      expect(ImageAspectRatioStore.isValidAspectRatio(0), isFalse);
      expect(ImageAspectRatioStore.isValidAspectRatio(-1), isFalse);
      expect(ImageAspectRatioStore.isValidAspectRatio(double.nan), isFalse);
      expect(ImageAspectRatioStore.isValidAspectRatio(double.infinity), isFalse);
      expect(
          ImageAspectRatioStore.isValidAspectRatio(double.negativeInfinity),
          isFalse);
    });
  });

  group('ImageAspectRatioStore.aspectRatioFromSize', () {
    test('returns height/width for valid sizes', () {
      expect(ImageAspectRatioStore.aspectRatioFromSize(400, 300), 0.75);
      expect(ImageAspectRatioStore.aspectRatioFromSize(100, 200), 2.0);
    });

    test('returns null for invalid sizes', () {
      expect(ImageAspectRatioStore.aspectRatioFromSize(0, 100), isNull);
      expect(ImageAspectRatioStore.aspectRatioFromSize(100, 0), isNull);
      expect(ImageAspectRatioStore.aspectRatioFromSize(-10, 100), isNull);
      expect(ImageAspectRatioStore.aspectRatioFromSize(100, -10), isNull);
      expect(
          ImageAspectRatioStore.aspectRatioFromSize(double.nan, 100), isNull);
      expect(
          ImageAspectRatioStore.aspectRatioFromSize(100, double.infinity),
          isNull);
    });
  });

  group('ImageAspectRatioStore.fallbackAspectRatio', () {
    test('is 3/4', () {
      expect(ImageAspectRatioStore.fallbackAspectRatio, 3 / 4);
    });
  });

  group('ImageAspectRatioStore.isValidNaturalWidth', () {
    test('accepts positive finite widths', () {
      expect(ImageAspectRatioStore.isValidNaturalWidth(1), isTrue);
      expect(ImageAspectRatioStore.isValidNaturalWidth(320), isTrue);
    });

    test('rejects non-positive and non-finite widths', () {
      expect(ImageAspectRatioStore.isValidNaturalWidth(0), isFalse);
      expect(ImageAspectRatioStore.isValidNaturalWidth(-10), isFalse);
      expect(ImageAspectRatioStore.isValidNaturalWidth(double.nan), isFalse);
      expect(
          ImageAspectRatioStore.isValidNaturalWidth(double.infinity), isFalse);
    });
  });

  group('ImageAspectRatioStore.save', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('image_aspect_ratio_');
      Hive.init(tempDir.path);
      await Hive.openBox(ImageAspectRatioStore.boxName);
    });

    tearDown(() async {
      if (Hive.isBoxOpen(ImageAspectRatioStore.boxName)) {
        await Hive.box(ImageAspectRatioStore.boxName).close();
      }
      await Hive.deleteBoxFromDisk(ImageAspectRatioStore.boxName);
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('skips rewrite when ratio and width are unchanged', () async {
      const url = 'https://example.com/a.png';
      final store = ImageAspectRatioStore.instance;
      await store.save(url, 0.75, naturalWidth: 400);
      final stored = Hive.box(ImageAspectRatioStore.boxName).get(url);

      await store.save(url, 0.75, naturalWidth: 400);
      expect(
        identical(Hive.box(ImageAspectRatioStore.boxName).get(url), stored),
        isTrue,
      );
    });

    test('skips rewrite when only ratio is sent and already matches', () async {
      const url = 'https://example.com/b.png';
      final store = ImageAspectRatioStore.instance;
      await store.save(url, 0.5, naturalWidth: 200);
      final first = Hive.box(ImageAspectRatioStore.boxName).get(url);

      await store.save(url, 0.5);
      expect(
        identical(Hive.box(ImageAspectRatioStore.boxName).get(url), first),
        isTrue,
      );
    });

    test('writes when width is new for the same ratio', () async {
      const url = 'https://example.com/c.png';
      final store = ImageAspectRatioStore.instance;
      await store.save(url, 0.75);
      expect(store.naturalWidth(url), isNull);

      await store.save(url, 0.75, naturalWidth: 320);
      expect(store.naturalWidth(url), 320);
      expect(store.aspectRatio(url), 0.75);
    });
  });
}
