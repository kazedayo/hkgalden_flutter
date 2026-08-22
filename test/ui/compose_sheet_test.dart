import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/ui/common/compose_page/compose_page.dart';

void main() {
  testWidgets('compose opens as a fullscreen dialog and closes on CloseButton',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showComposeSheet(
                context: context,
                builder: (_) => Scaffold(
                  appBar: AppBar(leading: const CloseButton()),
                  body: const Text('compose-body'),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final route = ModalRoute.of(
      tester.element(find.text('compose-body')),
    );
    expect(route?.fullscreenDialog, isTrue);
    expect(find.byType(BottomSheet), findsNothing);

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    expect(find.text('compose-body'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
