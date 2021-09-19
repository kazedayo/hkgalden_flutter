import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

class UserThreadListRepository {
  final _api = HKGaldenApi();

  Future<List<Thread>?> getUserThreadList(String userId, int page) =>
      _api.getUserThreadList(userId, page);
}
