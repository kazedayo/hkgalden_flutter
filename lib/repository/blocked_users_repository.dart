import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

class BlockedUsersRepository {
  BlockedUsersRepository({HKGaldenApi? api}) : _api = api ?? HKGaldenApi();

  final HKGaldenApi _api;

  Future<List<User>?> getBlockedUsers() => _api.getBlockedUser();
}
