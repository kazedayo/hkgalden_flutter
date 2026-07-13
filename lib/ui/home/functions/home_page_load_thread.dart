part of '../home_page.dart';

void _loadThread(BuildContext context, Thread thread) {
  final saved =
      ThreadReadingPositionStore.instance.get(thread.threadId);
  // Prefer last-seen page + floor when reopening a previously viewed thread.
  // Clamp page if the thread has fewer pages than when last viewed.
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
