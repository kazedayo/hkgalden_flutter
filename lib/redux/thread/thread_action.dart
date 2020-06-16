import 'package:hkgalden_flutter/models/thread.dart';

class RequestThreadAction {
  final String channelId;

  RequestThreadAction({
    this.channelId
  });
}

class UpdateThreadAction {
  final List<Thread> threads;

  UpdateThreadAction({
    this.threads
  });
}

class RequestThreadErrorAction {}