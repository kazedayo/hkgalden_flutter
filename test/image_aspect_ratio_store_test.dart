import 'package:hkgalden_flutter/utils/image_aspect_ratio_store.dart';
import 'package:test/test.dart';

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
    test('is 3/4 so reserved height = maxWidth * 3/4', () {
      expect(ImageAspectRatioStore.fallbackAspectRatio, 3 / 4);
      const maxWidth = 400.0;
      expect(maxWidth * ImageAspectRatioStore.fallbackAspectRatio, 300.0);
    });
  });
}
