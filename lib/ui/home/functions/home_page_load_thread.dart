part of '../home_page.dart';

void _loadThread(BuildContext context, Thread thread) {
  Navigator.of(context).pushNamed(
    '/Thread',
    arguments: ThreadPageArguments(
        threadId: thread.threadId,
        title: thread.title,
        page: 1,
        locked: thread.status == 'locked'),
  );
}
