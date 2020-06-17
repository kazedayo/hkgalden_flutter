import 'package:hkgalden_flutter/models/session_user.dart';

class RequestSessionUserAction {}

class UpdateSessionUserAction {
  final SessionUser sessionUser;

  UpdateSessionUserAction({
    this.sessionUser,
  });
}

class RequestSessionUserErrorAction {}

class RemoveSessionUserAction{}



