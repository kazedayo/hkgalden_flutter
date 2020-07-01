import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/thread.dart';

class RequestThreadAction {
  final int threadId;
  final int page;
  final bool isInitialLoad;

  RequestThreadAction({
    this.threadId,
    this.page,
    this.isInitialLoad,
  });
}

class UpdateThreadAction {
  final Thread thread;
  final int page;
  final bool isInitialLoad;

  UpdateThreadAction({
    this.thread,
    this.page,
    this.isInitialLoad,
  });
}

class AppendReplyToThreadAction {
  final Reply reply;

  AppendReplyToThreadAction({
    this.reply,
  });
}

class RequestThreadErrorAction {
  final int threadId;
  final int page;
  final bool isInitialLoad;

  RequestThreadErrorAction(this.threadId, this.page, this.isInitialLoad);
}
