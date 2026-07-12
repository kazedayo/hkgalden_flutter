import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

class SessionUserRepository {
  SessionUserRepository({HKGaldenApi? api}) : _api = api ?? HKGaldenApi();

  final HKGaldenApi _api;

  Future<User?> getSessionUser() => _api.getSessionUserQuery();

  Future<bool?> blockUser(String userId) => _api.blockUser(userId);
}
