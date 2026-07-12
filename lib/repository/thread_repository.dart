import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

class ThreadRepository {
  ThreadRepository({HKGaldenApi? api}) : _api = api ?? HKGaldenApi();

  final HKGaldenApi _api;

  Future<Thread?> getThread(int id, int page) => _api.getThreadQuery(id, page);

  Future<Reply?> sendReply(int threadId, String html, {String? parentId}) =>
      _api.sendReply(threadId, html, parentId: parentId);

  Future<int?> createThread(String title, List<String> tags, String html) =>
      _api.createThread(title, tags, html);
}
