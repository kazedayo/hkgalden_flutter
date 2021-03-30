import 'package:hkgalden_flutter/models/thread.dart';

class RequestUserThreadListAction {
  final String userId;
  final int page;

  RequestUserThreadListAction({
    required this.userId,
    required this.page,
  });
}

class UpdateUserThreadListAction {
  final List<Thread> threads;

  UpdateUserThreadListAction({required this.threads});
}

class RequestUserThreadListErrorAction {}
