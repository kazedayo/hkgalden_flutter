import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

class ThreadRepository {
  final _api = HKGaldenApi();

  Future<Thread?> getThread(int id, int page) async =>
      _api.getThreadQuery(id, page);
}
