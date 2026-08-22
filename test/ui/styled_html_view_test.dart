import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/ui/common/styled_html_view.dart';

void main() {
  testWidgets('quote preview renders galden icon smileys as images',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StyledHtmlView(
            htmlString:
                '<p>hi<icon src="https://s.hkgalden.org/smilies/hkg/A7WUrp9FZ62.gif"></icon></p>',
          ),
        ),
      ),
    );

    expect(find.byType(Image), findsOneWidget);
  });
}
