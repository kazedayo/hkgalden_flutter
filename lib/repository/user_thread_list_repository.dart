import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

class UserThreadListRepository {
  UserThreadListRepository({HKGaldenApi? api}) : _api = api ?? HKGaldenApi();

  final HKGaldenApi _api;

  Future<List<Thread>?> getUserThreadList(String userId, int page) =>
      _api.getUserThreadList(userId, page);
}
