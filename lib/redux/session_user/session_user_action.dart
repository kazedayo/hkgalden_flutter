import 'package:hkgalden_flutter/models/user.dart';

class RequestSessionUserAction {}

class UpdateSessionUserAction {
  final User sessionUser;

  UpdateSessionUserAction({
    this.sessionUser,
  });
}

class RequestSessionUserErrorAction {}

class AppendUserToBlockListAction {
  final String userId;

  AppendUserToBlockListAction(this.userId);
}

class RemoveSessionUserAction {}
