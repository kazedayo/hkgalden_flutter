// Mocks generated by Mockito 5.0.3 from annotations
// in hkgalden_flutter/test/bloc_tests/thread_bloc_test.dart.
// Do not manually edit this file.

import 'dart:async' as _i4;

import 'package:hkgalden_flutter/models/thread.dart' as _i2;
import 'package:hkgalden_flutter/repository/thread_repository.dart' as _i3;
import 'package:mockito/mockito.dart' as _i1;

// ignore_for_file: comment_references
// ignore_for_file: unnecessary_parenthesis

class _FakeThread extends _i1.Fake implements _i2.Thread {}

/// A class which mocks [ThreadRepository].
///
/// See the documentation for Mockito's code generation for more information.
class MockThreadRepository extends _i1.Mock implements _i3.ThreadRepository {
  MockThreadRepository() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i4.Future<_i2.Thread?> getThread(int? id, int? page) =>
      (super.noSuchMethod(Invocation.method(#getThread, [id, page]),
          returnValue: Future.value(_FakeThread())) as _i4.Future<_i2.Thread?>);
}