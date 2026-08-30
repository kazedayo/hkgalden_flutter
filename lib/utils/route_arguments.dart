import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/models/thread_reading_position.dart';
import 'package:hkgalden_flutter/utils/thread_reading_position_store.dart';

class ThreadPageArguments {
  final String title;
  final int threadId;
  final int page;
  final bool locked;

  final int? floor;

  ThreadPageArguments(
      {required this.title,
      required this.threadId,
      required this.page,
      required this.locked,
      this.floor});

  factory ThreadPageArguments.fromThread(Thread thread) {
    final saved = ThreadReadingPositionStore.instance.get(thread.threadId);
    final maxPage =
        (thread.totalReplies.toDouble() / kRepliesPerPage).ceil().clamp(1, 0x7fffffff);
    var page = saved?.page ?? 1;
    var floor = saved?.floor;
    if (page > maxPage) {
      page = maxPage;
      floor = null;
    }
    return ThreadPageArguments(
      threadId: thread.threadId,
      title: thread.title,
      page: page,
      locked: thread.status == 'locked',
      floor: floor,
    );
  }
}
