import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/ui/common/stop_scroll_on_inactive.dart';

void main() {
  testWidgets('inactive lifecycle does not fling list on resume', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => StopScrollOnInactive(child: child!),
        home: ListView.builder(
          controller: controller,
          itemCount: 40,
          itemBuilder: (_, i) => SizedBox(height: 80, child: Text('$i')),
        ),
      ),
    );

    await tester.fling(find.byType(ListView), const Offset(0, -800), 3000);
    await tester.pump();
    expect(controller.offset, greaterThan(0));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    final frozen = controller.offset;

    await tester.pump(const Duration(seconds: 1));
    expect(controller.offset, frozen);
  });
}
