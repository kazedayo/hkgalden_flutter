import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/repository/session_user_repository.dart';
import 'package:hkgalden_flutter/repository/thread_repository.dart';
import 'package:hkgalden_flutter/ui/thread/thread_page.dart';
import 'package:hkgalden_flutter/utils/route_arguments.dart';

void main() {
  testWidgets('popping ThreadPage does not throw while persisting position',
      (tester) async {
    final navigator = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<ThreadRepository>.value(
            value: _HangingThreadRepository(),
          ),
        ],
        child: BlocProvider(
          create: (_) => SessionUserBloc(
            repository: _FakeSessionUserRepository(),
          ),
          child: MaterialApp(
            navigatorKey: navigator,
            home: const Scaffold(body: Text('list')),
          ),
        ),
      ),
    );

    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const ThreadPage(),
        settings: RouteSettings(
          arguments: ThreadPageArguments(
            title: 't',
            threadId: 1,
            page: 1,
            locked: false,
            floor: 10,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    navigator.currentState!.pop();
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('list'), findsOneWidget);
  });
}

class _HangingThreadRepository extends ThreadRepository {
  @override
  Future<Thread?> getThread(int id, int page) => Completer<Thread?>().future;
}

class _FakeSessionUserRepository extends SessionUserRepository {
  @override
  Future<User?> getSessionUser() async => null;
}
