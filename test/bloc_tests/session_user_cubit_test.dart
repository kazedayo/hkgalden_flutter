import 'package:hkgalden_flutter/bloc/session_user/session_user_cubit.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

class _FakeApi extends Fake implements HKGaldenApi {
  _FakeApi({this.sessionUser, this.unblockResult = true});

  final User? sessionUser;
  final bool? unblockResult;
  final List<String> unblockCalls = [];

  @override
  Future<User?> getSessionUserQuery() async => sessionUser;

  @override
  Future<bool?> unblockUser(String userId) async {
    unblockCalls.add(userId);
    return unblockResult;
  }
}

void main() {
  const session = User(
    userId: 'me',
    nickName: 'me',
    avatar: '',
    userGroup: [],
    blockedUsers: ['blocked'],
  );

  test('removeUserFromBlockList unblocks via API and drops the id', () async {
    final api = _FakeApi(sessionUser: session);
    final cubit = SessionUserCubit(api: api);
    await cubit.requestSessionUser();

    expect(await cubit.removeUserFromBlockList('blocked'), isTrue);
    expect(api.unblockCalls, ['blocked']);
    expect(
      (cubit.state as SessionUserLoaded).sessionUser.blockedUsers,
      isEmpty,
    );
    await cubit.close();
  });

  test('removeUserFromBlockList keeps the id when API fails', () async {
    final api = _FakeApi(sessionUser: session, unblockResult: null);
    final cubit = SessionUserCubit(api: api);
    await cubit.requestSessionUser();

    expect(await cubit.removeUserFromBlockList('blocked'), isFalse);
    expect(
      (cubit.state as SessionUserLoaded).sessionUser.blockedUsers,
      ['blocked'],
    );
    await cubit.close();
  });
}
