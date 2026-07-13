part of '../home_page.dart';

void _loadThread(BuildContext context, Thread thread) {
  final saved =
      ThreadReadingPositionStore.instance.get(thread.threadId);
  final maxPage =
      (thread.totalReplies.toDouble() / 50.0).ceil().clamp(1, 0x7fffffff);
  var page = saved?.page ?? 1;
  var floor = saved?.floor;
  if (page > maxPage) {
    page = maxPage;
    floor = null;
  }
  Navigator.of(context).pushNamed(
    '/Thread',
    arguments: ThreadPageArguments(
        threadId: thread.threadId,
        title: thread.title,
        page: page,
        locked: thread.status == 'locked',
        floor: floor),
  );
}
