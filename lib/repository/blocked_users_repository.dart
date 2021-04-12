import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

class BlockedUsersRepository {
  final _api = HKGaldenApi();

  Future<List<User>?> getBlockedUsers() => _api.getBlockedUser();
}
