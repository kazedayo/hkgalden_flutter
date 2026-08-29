import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/ui/thread/widgets/thread_page_app_bar.dart';

bool _fitsInTwoLines(String title, double fontSize, double maxWidth) {
  final painter = TextPainter(
    text: TextSpan(
      text: title,
      style: TextStyle(fontWeight: FontWeight.w700, fontSize: fontSize),
    ),
    maxLines: 2,
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: maxWidth);
  return !painter.didExceedMaxLines;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const title = 'THE IDOLM@STER Series（アイドルマスター シリーズ）第3章';

  test('returned font size actually fits the title in 2 lines', () {
    const maxWidth = 300.0;
    final size = fittingFontSize(title, maxWidth);
    expect(_fitsInTwoLines(title, size, maxWidth), isTrue,
        reason: 'size $size should fit "$title" in 2 lines at $maxWidth');
  });

  test('shrinks only when needed', () {
    expect(fittingFontSize('短標題', 300), 18,
        reason: 'short title should keep the max size');
    expect(fittingFontSize(title, 300), lessThan(fittingFontSize('短標題', 300)),
        reason: 'long title must shrink below the short-title size');
  });
}
