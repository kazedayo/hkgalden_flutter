import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_cubit.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/ui/user_detail/block_list_page.dart';

const _session = User(
  userId: 'me',
  nickName: 'me',
  avatar: '',
  userGroup: [],
  blockedUsers: ['blocked'],
);

const _blocked = User(
  userId: 'blocked',
  nickName: 'BlockedNick',
  avatar: '',
  userGroup: [],
  gender: 'M',
  blockedUsers: [],
);

void main() {
  testWidgets('swipe unblocks user via API and removes the cell', (tester) async {
    final api = _FakeApi(blockedUsers: [_blocked], sessionUser: _session);
    final cubit = SessionUserCubit(api: api);
    await cubit.requestSessionUser();

    await tester.pumpWidget(_app(api: api, cubit: cubit));
    await tester.pump();
    await tester.pump();

    expect(find.text('BlockedNick'), findsOneWidget);

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(api.unblockCalls, ['blocked']);
    expect(find.text('BlockedNick'), findsNothing);
    expect(
      (cubit.state as SessionUserLoaded).sessionUser.blockedUsers,
      isEmpty,
    );
  });

  testWidgets('failed unblock keeps the cell', (tester) async {
    final api = _FakeApi(
      blockedUsers: [_blocked],
      sessionUser: _session,
      unblockResult: null,
    );
    final cubit = SessionUserCubit(api: api);
    await cubit.requestSessionUser();

    await tester.pumpWidget(_app(api: api, cubit: cubit));
    await tester.pump();
    await tester.pump();

    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('BlockedNick'), findsOneWidget);
    expect(
      (cubit.state as SessionUserLoaded).sessionUser.blockedUsers,
      ['blocked'],
    );
  });
}

Widget _app({required _FakeApi api, required SessionUserCubit cubit}) {
  return MultiRepositoryProvider(
    providers: [RepositoryProvider<HKGaldenApi>.value(value: api)],
    child: BlocProvider.value(
      value: cubit,
      child: const MaterialApp(home: Scaffold(body: BlockListPage())),
    ),
  );
}

class _FakeApi extends Fake implements HKGaldenApi {
  _FakeApi({
    this.blockedUsers = const [],
    this.sessionUser,
    this.unblockResult = true,
  });

  final List<User> blockedUsers;
  final User? sessionUser;
  final bool? unblockResult;
  final List<String> unblockCalls = [];

  @override
  Future<List<User>?> getBlockedUser() async => blockedUsers;

  @override
  Future<User?> getSessionUserQuery() async => sessionUser;

  @override
  Future<bool?> unblockUser(String userId) async {
    unblockCalls.add(userId);
    return unblockResult;
  }
}
