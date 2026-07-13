import 'package:bloc_test/bloc_test.dart';
import 'package:hkgalden_flutter/bloc/blocked_users/blocked_users_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/bloc/thread_list/thread_list_bloc.dart';
import 'package:hkgalden_flutter/bloc/user_thread_list/user_thread_list_bloc.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/repository/blocked_users_repository.dart';
import 'package:hkgalden_flutter/repository/thread_list_repository.dart';
import 'package:hkgalden_flutter/repository/thread_repository.dart';
import 'package:hkgalden_flutter/repository/user_thread_list_repository.dart';
import 'package:test/test.dart';

class _FakeThreadListRepository extends ThreadListRepository {
  _FakeThreadListRepository(this._handler);
  final Future<List<Thread>?> Function(String id, int page) _handler;

  @override
  Future<List<Thread>?> getThreadList(String id, int page) => _handler(id, page);
}

class _FakeBlockedUsersRepository extends BlockedUsersRepository {
  _FakeBlockedUsersRepository(this.result);
  final List<User>? result;
  int calls = 0;

  @override
  Future<List<User>?> getBlockedUsers() async {
    calls++;
    return result;
  }
}

class _FakeUserThreadListRepository extends UserThreadListRepository {
  _FakeUserThreadListRepository(this.result);
  final List<Thread>? result;

  @override
  Future<List<Thread>?> getUserThreadList(String userId, int page) async =>
      result;
}

class _FakeThreadRepository extends ThreadRepository {
  _FakeThreadRepository(this._handler);
  final Future<Thread?> Function(int id, int page) _handler;

  @override
  Future<Thread?> getThread(int id, int page) => _handler(id, page);
}

void main() {
  group('ThreadListBloc append failure', () {
    blocTest<ThreadListBloc, ThreadListState>(
      'restores previous loaded state instead of re-dispatching forever',
      build: () {
        var page2Calls = 0;
        final repo = _FakeThreadListRepository((id, page) async {
          if (page == 1) {
            return [];
          }
          page2Calls++;
          if (page2Calls > 3) {
            fail('append path re-dispatched more than once: $page2Calls');
          }
          return null;
        });
        return ThreadListBloc(repository: repo);
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
      'emits BlockedUsersError when repository returns null',
      build: () => BlockedUsersBloc(
          repository: _FakeBlockedUsersRepository(null)),
      act: (bloc) => bloc.add(RequestBlockedUsersEvent()),
      expect: () => [
        isA<BlockedUsersLoading>(),
        isA<BlockedUsersError>(),
      ],
    );

    blocTest<BlockedUsersBloc, BlockedUsersState>(
      'emits BlockedUsersLoaded when repository returns list',
      build: () => BlockedUsersBloc(
          repository: _FakeBlockedUsersRepository(const [])),
      act: (bloc) => bloc.add(RequestBlockedUsersEvent()),
      expect: () => [
        isA<BlockedUsersLoading>(),
        const BlockedUsersLoaded(blockedUsers: []),
      ],
    );
  });

  group('UserThreadListBloc error path', () {
    blocTest<UserThreadListBloc, UserThreadListState>(
      'emits UserThreadListError when repository returns null',
      build: () => UserThreadListBloc(
          repository: _FakeUserThreadListRepository(null)),
      act: (bloc) =>
          bloc.add(const RequestUserThreadListEvent(userId: 'u1', page: 1)),
      expect: () => [
        isA<UserThreadListLoading>(),
        isA<UserThreadListError>(),
      ],
    );

    blocTest<UserThreadListBloc, UserThreadListState>(
      'emits UserThreadListLoaded when repository returns list',
      build: () => UserThreadListBloc(
          repository: _FakeUserThreadListRepository(const [])),
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
        final repo = _FakeThreadRepository((id, page) async {
          if (page == 1) {
            return Thread.initial();
          }
          return null;
        });
        return ThreadBloc(repository: repo);
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
