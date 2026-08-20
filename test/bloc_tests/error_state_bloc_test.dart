import 'package:bloc_test/bloc_test.dart';
import 'package:hkgalden_flutter/bloc/blocked_users/blocked_users_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread_list/thread_list_bloc.dart';
import 'package:hkgalden_flutter/bloc/user_thread_list/user_thread_list_bloc.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

class _FakeThreadListApi extends Fake implements HKGaldenApi {
  _FakeThreadListApi(this._handler);
  final Future<List<Thread>?> Function(String id, int page) _handler;

  @override
  Future<List<Thread>?> getThreadListQuery(String id, int page) =>
      _handler(id, page);
}

class _FakeBlockedUsersApi extends Fake implements HKGaldenApi {
  _FakeBlockedUsersApi(this.result);
  final List<User>? result;

  @override
  Future<List<User>?> getBlockedUser() async => result;
}

class _FakeUserThreadListApi extends Fake implements HKGaldenApi {
  _FakeUserThreadListApi(this.result);
  final List<Thread>? result;

  @override
  Future<List<Thread>?> getUserThreadList(String userId, int page) async =>
      result;
}

class _FakeThreadApi extends Fake implements HKGaldenApi {
  _FakeThreadApi(this._handler);
  final Future<Thread?> Function(int id, int page) _handler;

  @override
  Future<Thread?> getThreadQuery(int id, int page) => _handler(id, page);
}

void main() {
  group('ThreadListBloc append failure', () {
    blocTest<ThreadListBloc, ThreadListState>(
      'restores previous loaded state instead of re-dispatching forever',
      build: () {
        var page2Calls = 0;
        final api = _FakeThreadListApi((id, page) async {
          if (page == 1) {
            return [];
          }
          page2Calls++;
          if (page2Calls > 3) {
            fail('append path re-dispatched more than once: $page2Calls');
          }
          return null;
        });
        return ThreadListBloc(api: api);
      },
      act: (bloc) async {
        bloc.add(const RequestThreadListEvent(
            channelId: 'bw', page: 1, isRefresh: false));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RequestThreadListEvent(
            channelId: 'bw', page: 2, isRefresh: false));
      },
      expect: () => [
        isA<ThreadListLoading>(),
        const ThreadListLoaded(
            threads: [], currentChannelId: 'bw', currentPage: 1),
        isA<ThreadListAppending>(),
        const ThreadListLoaded(
            threads: [], currentChannelId: 'bw', currentPage: 1),
      ],
      wait: const Duration(milliseconds: 50),
    );
  });

  group('BlockedUsersBloc error path', () {
    blocTest<BlockedUsersBloc, BlockedUsersState>(
      'emits BlockedUsersError when API returns null',
      build: () => BlockedUsersBloc(api: _FakeBlockedUsersApi(null)),
      act: (bloc) => bloc.add(RequestBlockedUsersEvent()),
      expect: () => [
        isA<BlockedUsersLoading>(),
        isA<BlockedUsersError>(),
      ],
    );

    blocTest<BlockedUsersBloc, BlockedUsersState>(
      'emits BlockedUsersLoaded when API returns list',
      build: () => BlockedUsersBloc(api: _FakeBlockedUsersApi(const [])),
      act: (bloc) => bloc.add(RequestBlockedUsersEvent()),
      expect: () => [
        isA<BlockedUsersLoading>(),
        const BlockedUsersLoaded(blockedUsers: []),
      ],
    );
  });

  group('UserThreadListBloc error path', () {
    blocTest<UserThreadListBloc, UserThreadListState>(
      'emits UserThreadListError when API returns null',
      build: () => UserThreadListBloc(api: _FakeUserThreadListApi(null)),
      act: (bloc) =>
          bloc.add(const RequestUserThreadListEvent(userId: 'u1', page: 1)),
      expect: () => [
        isA<UserThreadListLoading>(),
        isA<UserThreadListError>(),
      ],
    );

    blocTest<UserThreadListBloc, UserThreadListState>(
      'emits UserThreadListLoaded when API returns list',
      build: () => UserThreadListBloc(api: _FakeUserThreadListApi(const [])),
      act: (bloc) =>
          bloc.add(const RequestUserThreadListEvent(userId: 'u1', page: 1)),
      expect: () => [
        isA<UserThreadListLoading>(),
        const UserThreadListLoaded(page: 1, userThreadList: []),
      ],
    );
  });

  group('ThreadBloc pagination failure', () {
    blocTest<ThreadBloc, ThreadState>(
      'restores previous ThreadLoaded instead of full-page ThreadError',
      build: () {
        final api = _FakeThreadApi((id, page) async {
          if (page == 1) {
            return Thread.initial();
          }
          return null;
        });
        return ThreadBloc(api: api);
      },
      act: (bloc) async {
        bloc.add(const RequestThreadEvent(
            threadId: 1, page: 1, isInitialLoad: true));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RequestThreadEvent(
            threadId: 1, page: 2, isInitialLoad: false));
      },
      expect: () => [
        isA<ThreadLoading>(),
        ThreadLoaded(
          thread: Thread.initial(),
          previousPages: Thread.initial(),
          currentPage: 1,
          endPage: 1,
        ),
        isA<ThreadAppending>(),
        ThreadLoaded(
          thread: Thread.initial(),
          previousPages: Thread.initial(),
          currentPage: 1,
          endPage: 1,
        ),
      ],
      wait: const Duration(milliseconds: 50),
    );
  });

  group('ThreadLoaded.props', () {
    test('two ThreadLoaded with different pages are not equal', () {
      final a = ThreadLoaded(
        thread: Thread.initial(),
        previousPages: Thread.initial(),
        currentPage: 1,
        endPage: 1,
      );
      final b = ThreadLoaded(
        thread: Thread.initial(),
        previousPages: Thread.initial(),
        currentPage: 2,
        endPage: 2,
      );
      expect(a, isNot(equals(b)));
      expect(a.props, [a.thread, a.previousPages, a.currentPage, a.endPage]);
    });

    test('identical ThreadLoaded values are equal via props', () {
      final a = ThreadLoaded(
        thread: Thread.initial(),
        previousPages: Thread.initial(),
        currentPage: 1,
        endPage: 1,
      );
      final b = ThreadLoaded(
        thread: Thread.initial(),
        previousPages: Thread.initial(),
        currentPage: 1,
        endPage: 1,
      );
      expect(a, equals(b));
    });
  });
}
