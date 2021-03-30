import 'package:hkgalden_flutter/models/thread.dart';

class RequestThreadListAction {
  final String channelId;
  final int page;
  final bool isRefresh;

  RequestThreadListAction(
      {required this.channelId, required this.page, required this.isRefresh});
}

class UpdateThreadListAction {
  final List<Thread> threads;
  final int page;
  final bool isRefresh;

  UpdateThreadListAction({
    required this.threads,
    required this.page,
    required this.isRefresh,
  });
}

class RequestThreadListErrorAction {
  final String channelId;
  final int page;
  final bool isRefresh;

  RequestThreadListErrorAction(this.channelId, this.page, this.isRefresh);
}
