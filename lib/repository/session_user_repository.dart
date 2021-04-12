import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';

class SessionUserRepository {
  final _api = HKGaldenApi();

  Future<User?> getSessionUser() => _api.getSessionUserQuery();
}
