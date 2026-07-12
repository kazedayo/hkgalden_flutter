import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

class ThreadListRepository {
  ThreadListRepository({HKGaldenApi? api}) : _api = api ?? HKGaldenApi();

  final HKGaldenApi _api;

  Future<List<Thread>?> getThreadList(String id, int page) =>
      _api.getThreadListQuery(id, page);
}
