import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/ui/home/thread_cell.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';

void main() {
  const user = User(
    userId: '1',
    nickName: 'nick',
    avatar: '',
    blockedUsers: [],
  );

  Reply reply() => Reply(
        floor: 1,
        author: user,
        authorNickname: 'nick',
        date: DateTime.utc(2024, 1, 1),
      );

  Thread thread({
    required String title,
    String status = '',
    String tagName = '吹水',
  }) =>
      Thread(
        threadId: title.hashCode,
        title: title,
        status: status,
        replies: [reply()],
        totalReplies: 3,
        tagName: tagName,
        tagColor: const Color(0xff45c17c),
      );

  Future<void> expectMeasuredHeight(
    WidgetTester tester, {
    required Thread item,
    required Size viewport,
  }) async {
    late ThemeData theme;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Builder(
          builder: (context) {
            theme = AppTheme.generate(context);
            return Theme(
              data: theme,
              child: MediaQuery(
                data: MediaQueryData(size: viewport),
                child: Scaffold(
                  body: UnconstrainedBox(
                    constrainedAxis: Axis.horizontal,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: viewport.width,
                      child: ThreadCell(
                        thread: item,
                        onTap: () {},
                        onLongPress: () {},
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final size = tester.getSize(find.byType(ThreadCell));
    final cellContext = tester.element(find.byType(ThreadCell));
    final measured = ThreadCell.measureHeight(
      context: cellContext,
      thread: item,
      maxWidth: viewport.width,
    );
    expect(
      measured,
      moreOrLessEquals(size.height, epsilon: 0.5),
      reason: 'title="${item.title}" locked=${item.status == 'locked'}',
    );
  }

  testWidgets('measured height matches a one-line title', (tester) async {
    await expectMeasuredHeight(
      tester,
      item: thread(title: '短標題'),
      viewport: const Size(400, 800),
    );
  });

  testWidgets('measured height matches a wrapping title', (tester) async {
    await expectMeasuredHeight(
      tester,
      item: thread(title: '這是一段很長的標題需要換行顯示在主題列表裡面而且不能被截斷'),
      viewport: const Size(360, 800),
    );
  });

  testWidgets('measured height matches a locked wrapping title', (tester) async {
    await expectMeasuredHeight(
      tester,
      item: thread(
        title: '已鎖定的長標題也要完整換行並且為鎖圖騰讓出寬度',
        status: 'locked',
      ),
      viewport: const Size(360, 800),
    );
  });
}
