import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

class ThreadListRepository {
  final _api = HKGaldenApi();

  Future<List<Thread>?> getThreadList(String id, int page) => _api.getThreadListQuery(id, page);
}
