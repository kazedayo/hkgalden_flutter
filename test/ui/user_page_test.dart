import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_cubit.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_page.dart';

const _user = User(
  userId: '1',
  nickName: 'tester',
  avatar: '',
  userGroup: [],
  gender: 'M',
  blockedUsers: [],
);

const _other = User(
  userId: '2',
  nickName: 'other',
  avatar: '',
  userGroup: [],
  gender: 'M',
  blockedUsers: [],
);

const _thread = Thread(
  threadId: 1,
  title: 't',
  status: '',
  replies: [],
  totalReplies: 0,
  tagName: '吹水',
  tagColor: Colors.blue,
);

void main() {
  testWidgets('user profile modal does not overflow on iPhone-sized screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(user: _other));

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();

    expect(find.text('主題列表'), findsOneWidget);
    expect(find.text('封鎖名單'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('own profile shows thread and block-list chips', (tester) async {
    final api = _FakeApi(sessionUser: _user, threads: [_thread]);
    final cubit = SessionUserCubit(api: api);
    await cubit.requestSessionUser();

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [RepositoryProvider<HKGaldenApi>.value(value: api)],
        child: BlocProvider.value(
          value: cubit,
          child: const MaterialApp(home: UserPage(user: _user)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('主題列表'), findsOneWidget);
    expect(find.text('封鎖名單'), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('t').hitTestable(), findsOneWidget);

    await tester.tap(find.text('封鎖名單'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '封鎖名單')).selected,
      isTrue,
    );
    expect(find.text('t').hitTestable(), findsNothing);

    await tester.tap(find.text('主題列表'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '主題列表')).selected,
      isTrue,
    );
    expect(find.text('t').hitTestable(), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    expect(
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '主題列表')).selected,
      isTrue,
    );
    expect(find.text('t').hitTestable(), findsOneWidget);
  });

  testWidgets('block success pops the sheet and toasts', (tester) async {
    final api = _FakeApi(sessionUser: _user);
    final cubit = SessionUserCubit(api: api);
    await cubit.requestSessionUser();

    await tester.pumpWidget(_app(user: _other, api: api, cubit: cubit));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('封鎖'));
    await tester.pumpAndSettle();

    expect(api.blockCalls, ['2']);
    expect(find.byType(UserPage), findsNothing);
    expect(find.text('已封鎖會員 other'), findsOneWidget);
  });

  testWidgets('block failure stays on the sheet and toasts', (tester) async {
    final api = _FakeApi(sessionUser: _user, blockResult: null);
    final cubit = SessionUserCubit(api: api);
    await cubit.requestSessionUser();

    await tester.pumpWidget(_app(user: _other, api: api, cubit: cubit));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('封鎖'));
    await tester.pumpAndSettle();

    expect(find.byType(UserPage), findsOneWidget);
    expect(find.text('封鎖失敗'), findsOneWidget);
  });

  testWidgets('block button ignores a second tap while in flight', (
    tester,
  ) async {
    final pending = Completer<bool?>();
    final api = _FakeApi(sessionUser: _user, blockResult: pending.future);
    final cubit = SessionUserCubit(api: api);
    await cubit.requestSessionUser();

    await tester.pumpWidget(_app(user: _other, api: api, cubit: cubit));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('封鎖'));
    await tester.pump();
    await tester.tap(find.text('封鎖'));
    await tester.pump();

    expect(api.blockCalls, ['2']);
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(find.byType(UserPage), findsNothing);
  });
}

Widget _app({
  required User user,
  HKGaldenApi? api,
  SessionUserCubit? cubit,
}) {
  final resolvedApi = api ?? _FakeApi();
  final app = MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => showModalBottomSheet(
            backgroundColor: Colors.transparent,
            enableDrag: false,
            context: context,
            builder: (_) => UserPage(user: user),
          ),
          child: const Text('open'),
        ),
      ),
    ),
  );
  return MultiRepositoryProvider(
    providers: [RepositoryProvider<HKGaldenApi>.value(value: resolvedApi)],
    child: cubit != null
        ? BlocProvider<SessionUserCubit>.value(value: cubit, child: app)
        : BlocProvider(
            create: (_) => SessionUserCubit(api: resolvedApi),
            child: app,
          ),
  );
}

class _FakeApi extends Fake implements HKGaldenApi {
  _FakeApi({
    this.threads = const [],
    this.sessionUser,
    this.blockResult = true,
  });

  final List<Thread> threads;
  final User? sessionUser;
  final Object? blockResult;
  final List<String> blockCalls = [];

  @override
  Future<List<Thread>?> getUserThreadList(String userId, int page) async =>
      threads;

  @override
  Future<List<User>?> getBlockedUser() async => [];

  @override
  Future<User?> getSessionUserQuery() async => sessionUser;

  @override
  Future<bool?> blockUser(String userId) async {
    blockCalls.add(userId);
    final result = blockResult;
    if (result is Future<bool?>) {
      return result;
    }
    return result as bool?;
  }
}
