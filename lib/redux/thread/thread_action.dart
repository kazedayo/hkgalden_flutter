import 'package:hkgalden_flutter/models/thread.dart';

class RequestThreadAction {
  final String channelId;
  final bool isRefresh;

  RequestThreadAction({
    this.channelId,
    this.isRefresh
  });
}

class UpdateThreadAction {
  final List<Thread> threads;

  UpdateThreadAction({
    this.threads
  });
}

class RequestThreadErrorAction {}