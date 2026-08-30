import 'package:hkgalden_flutter/bloc/session_user/session_user_cubit.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApi extends Fake implements HKGaldenApi {
  _FakeApi({
    this.sessionUser,
    this.blockResult = true,
    this.unblockResult = true,
  });

  final User? sessionUser;
  final bool? blockResult;
  final bool? unblockResult;
  final List<String> blockCalls = [];
  final List<String> unblockCalls = [];

  @override
  Future<User?> getSessionUserQuery() async => sessionUser;

  @override
  Future<bool?> blockUser(String userId) async {
    blockCalls.add(userId);
    return blockResult;
  }

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
    blockedUsers: ['blocked'],
  );

  test('appendUserToBlockList blocks via API and adds the id', () async {
    final api = _FakeApi(
      sessionUser: session.copyWith(blockedUsers: []),
    );
    final cubit = SessionUserCubit(api: api);
    await cubit.requestSessionUser();

    expect(await cubit.appendUserToBlockList('blocked'), isTrue);
    expect(api.blockCalls, ['blocked']);
    expect(
      (cubit.state as SessionUserLoaded).sessionUser.blockedUsers,
      ['blocked'],
    );
    await cubit.close();
  });

  test('appendUserToBlockList keeps the list when API fails', () async {
    final api = _FakeApi(
      sessionUser: session.copyWith(blockedUsers: []),
      blockResult: null,
    );
    final cubit = SessionUserCubit(api: api);
    await cubit.requestSessionUser();

    expect(await cubit.appendUserToBlockList('blocked'), isFalse);
    expect(
      (cubit.state as SessionUserLoaded).sessionUser.blockedUsers,
      isEmpty,
    );
    await cubit.close();
  });

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
