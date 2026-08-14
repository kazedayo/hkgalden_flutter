import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page_scroll_controller.dart';
import 'package:hkgalden_flutter/ui/thread/thread_restore_controller.dart';

void main() {
  group('resolveCenterAnchorIfNeeded + centerStartIndex', () {
    test('no floor → 0', () {
      final restore = ThreadRestoreController();
      final state = _loaded(floors: [1, 2, 3, 4, 5]);
      restore.resolveCenterAnchorIfNeeded(state);
      expect(restore.centerStartIndex(state.thread.replies), 0);
    });

    test('mid-list requested floor → index of first reply with floor >= requested',
        () {
      final restore = ThreadRestoreController();
      restore.captureArgsFloor(3);
      final state = _loaded(floors: [1, 2, 4, 5]);
      restore.resolveCenterAnchorIfNeeded(state);
      expect(restore.centerAnchorFloor, 4);
      expect(restore.centerStartIndex(state.thread.replies), 2);
    });

    test('requested >= last floor → index of last reply', () {
      final restore = ThreadRestoreController();
      restore.captureArgsFloor(10);
      final state = _loaded(floors: [1, 2, 3, 4, 5]);
      restore.resolveCenterAnchorIfNeeded(state);
      expect(restore.centerAnchorFloor, 5);
      expect(restore.centerStartIndex(state.thread.replies), 4);
    });

    test('seedCachedFloor matches resolved floor', () {
      final mid = ThreadRestoreController();
      mid.captureArgsFloor(3);
      final state = _loaded(floors: [1, 2, 3, 4, 5]);
      mid.resolveCenterAnchorIfNeeded(state);
      expect(mid.seedCachedFloor(state), 3);

      final last = ThreadRestoreController();
      last.captureArgsFloor(99);
      last.resolveCenterAnchorIfNeeded(state);
      expect(last.seedCachedFloor(state), 5);

      final none = ThreadRestoreController();
      none.resolveCenterAnchorIfNeeded(state);
      expect(none.seedCachedFloor(state), 1);
    });
  });

  testWidgets('pinCenterIfNeeded does not throw when pixels == 0',
      (tester) async {
    final scrollController = ThreadPageScrollController();
    addTearDown(scrollController.dispose);
    final restore = ThreadRestoreController();

    await tester.pumpWidget(
      MaterialApp(
        home: CustomScrollView(
          controller: scrollController,
          slivers: const [
            SliverToBoxAdapter(child: SizedBox(height: 200)),
          ],
        ),
      ),
    );

    expect(scrollController.hasClients, isTrue);
    expect(scrollController.position.pixels, 0);
    restore.pinCenterIfNeeded(scrollController);
    expect(tester.takeException(), isNull);
  });
}

ThreadLoaded _loaded({required List<int> floors}) {
  const author = User(
    userId: '1',
    nickName: 'n',
    avatar: '',
    userGroup: [],
    blockedUsers: [],
  );
  final replies = [
    for (final floor in floors)
      Reply(
        floor: floor,
        author: author,
        authorNickname: 'n',
        date: DateTime.utc(2024, 1, 1),
      ),
  ];
  return ThreadLoaded(
    thread: Thread.initial().copyWith(replies: replies),
    previousPages: Thread.initial(),
    currentPage: 1,
    endPage: 1,
  );
}
