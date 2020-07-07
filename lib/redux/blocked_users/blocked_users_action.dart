import 'package:hkgalden_flutter/models/user.dart';

class RequestBlockedUsersAction {}

class UpdateBlockedUsersAction {
  final List<User> blockedUsers;

  UpdateBlockedUsersAction(this.blockedUsers);
}

class RequestBlockedUsersErrorAction {}
