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

class UpdateThreadListAction {
  final List<Thread> threads;
  final int page;
  final bool isRefresh;

  UpdateThreadListAction({
    this.threads,
    this.page,
    this.isRefresh,
  });
}

class RequestThreadListErrorAction {
  final String channelId;
  final int page;
  final bool isRefresh;

  RequestThreadListErrorAction(this.channelId, this.page, this.isRefresh);
}