import 'package:hkgalden_flutter/models/thread.dart';

class RequestThreadListAction {
  final String channelId;
  final int page;
  final bool isRefresh;

  RequestThreadListAction({
    this.channelId,
    this.page,
    this.isRefresh
  });
}

class RequestThreadAction {
  final int threadId;

  RequestThreadAction({
    this.threadId,
  });
}

class UpdateThreadListAction {
  final List<Thread> threads;

  UpdateThreadListAction({
    this.threads
  });
}

class UpdateThreadAction {
  final Thread thread;

  UpdateThreadAction({
    this.thread
  });
}

class RequestThreadListErrorAction {}

class RequestThreadErrorAction {}