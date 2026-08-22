import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_cubit.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:hkgalden_flutter/ui/user_detail/user_page.dart';
import 'package:hkgalden_flutter/utils/app_theme.dart';

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
    expect(find.text('t'), findsOneWidget);

    await tester.tap(find.text('封鎖名單'));
    await tester.pump();
    await tester.pump();

    expect(find.text('t'), findsNothing);

    await tester.tap(find.text('主題列表'));
    await tester.pump();
    await tester.pump();

    expect(find.text('t'), findsOneWidget);

    final theme = Theme.of(tester.element(find.byType(UserPage)));
    final unselectedFill = AppTheme.linkPreviewBackground(theme.colorScheme);
    for (final label in ['主題列表', '封鎖名單']) {
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, label),
      );
      expect(chip.color!.resolve({}), unselectedFill);
      expect(
        chip.color!.resolve({WidgetState.selected}),
        theme.colorScheme.secondary,
      );
    }
  });

  testWidgets('user thread list dividers use the app divider color', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<HKGaldenApi>.value(
            value: _FakeApi(threads: [_thread]),
          ),
        ],
        child: BlocProvider(
          create: (_) => SessionUserCubit(api: _FakeApi()),
          child: MaterialApp(
            home: Builder(
              builder: (context) => Theme(
                data: AppTheme.generate(context),
                child: const UserPage(user: _user),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final divider = tester.widget<Divider>(find.byType(Divider));
    expect(divider.color, AppTheme.dividerColor);
  });
}

Widget _app({required User user}) {
  final api = _FakeApi();
  return MultiRepositoryProvider(
    providers: [RepositoryProvider<HKGaldenApi>.value(value: api)],
    child: BlocProvider(
      create: (_) => SessionUserCubit(api: api),
      child: MaterialApp(
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
      ),
    ),
  );
}

class _FakeApi extends Fake implements HKGaldenApi {
  _FakeApi({this.threads = const [], this.sessionUser});

  final List<Thread> threads;
  final User? sessionUser;

  @override
  Future<List<Thread>?> getUserThreadList(String userId, int page) async =>
      threads;

  @override
  Future<List<User>?> getBlockedUser() async => [];

  @override
  Future<User?> getSessionUserQuery() async => sessionUser;
}
