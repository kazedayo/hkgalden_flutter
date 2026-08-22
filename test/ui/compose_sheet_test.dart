import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/ui/common/compose_page/compose_page.dart';

void main() {
  testWidgets('compose sheet stays below top view padding', (tester) async {
    const topInset = 59.0;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: topInset, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: topInset, bottom: 34);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showComposeSheet(
              context: context,
              builder: (_) => const ColoredBox(
                key: Key('compose-sheet-body'),
                color: Colors.red,
                child: SizedBox.expand(),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.byKey(const Key('compose-sheet-body'))).dy,
      topInset,
    );
  });
}
