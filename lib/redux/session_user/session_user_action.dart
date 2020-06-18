import 'package:hkgalden_flutter/models/user.dart';

class RequestSessionUserAction {}

class UpdateSessionUserAction {
  final User sessionUser;

  UpdateSessionUserAction({
    this.sessionUser,
  });
}

class RequestSessionUserErrorAction {}

class RemoveSessionUserAction{}



