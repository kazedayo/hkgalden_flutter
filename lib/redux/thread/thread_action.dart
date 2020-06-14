import 'package:hkgalden_flutter/models/thread.dart';

class RequestThreadAction {}

class UpdateThreadAction {
  final List<Thread> threads;

  UpdateThreadAction({
    this.threads
  });
}

class RequestThreadErrorAction {}