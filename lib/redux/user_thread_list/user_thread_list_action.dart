import 'package:hkgalden_flutter/models/thread.dart';

class RequestUserThreadListAction {
  final String userId;
  final int page;

  RequestUserThreadListAction({
    this.userId,
    this.page,
  });
}

class UpdateUserThreadListAction {
  final List<Thread> threads;

  UpdateUserThreadListAction({this.threads});
}

class RequestUserThreadListErrorAction {}
