import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/ui/common/full_screen_photo_view.dart';

void main() {
  Future<void> openViewer(
    WidgetTester tester, {
    required TargetPlatform platform,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: platform),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => FullScreenPhotoView.open(
              context,
              url: 'https://example.com/photo.png',
              intrinsicWidth: 200,
              intrinsicHeight: 200,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  double imageScale(WidgetTester tester) {
    var maxScale = 1.0;
    for (final transform in tester.widgetList<Transform>(
      find.byType(Transform),
    )) {
      final scale = transform.transform.getMaxScaleOnAxis();
      if (scale > maxScale) {
        maxScale = scale;
      }
    }
    return maxScale;
  }

  Future<void> doubleTapViewer(WidgetTester tester, Finder viewer) async {
    await tester.tap(viewer);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(viewer);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets('double tap cycles 1x, 2x, 3x', (tester) async {
    await openViewer(tester, platform: TargetPlatform.android);

    final viewer = find.byType(InteractiveViewer);
    expect(imageScale(tester), closeTo(1.0, 0.05));

    await doubleTapViewer(tester, viewer);
    expect(imageScale(tester), closeTo(2.0, 0.05));

    await doubleTapViewer(tester, viewer);
    expect(imageScale(tester), closeTo(3.0, 0.05));

    await doubleTapViewer(tester, viewer);
    expect(imageScale(tester), closeTo(1.0, 0.05));
  });

  testWidgets('swipe down dismisses on iOS', (tester) async {
    await openViewer(tester, platform: TargetPlatform.iOS);

    expect(find.byType(FullScreenPhotoView), findsOneWidget);

    await tester.drag(find.byType(InteractiveViewer), const Offset(0, 220));
    await tester.pumpAndSettle();

    expect(find.byType(FullScreenPhotoView), findsNothing);
  });

  testWidgets('swipe down does not dismiss on Android', (tester) async {
    await openViewer(tester, platform: TargetPlatform.android);

    expect(find.byType(FullScreenPhotoView), findsOneWidget);

    await tester.drag(find.byType(InteractiveViewer), const Offset(0, 220));
    await tester.pumpAndSettle();

    expect(find.byType(FullScreenPhotoView), findsOneWidget);
  });
}
