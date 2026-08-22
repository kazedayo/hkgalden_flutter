import 'package:bloc_test/bloc_test.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_cubit.dart';
import 'package:hkgalden_flutter/bloc/thread_list/thread_list_cubit.dart';
import 'package:hkgalden_flutter/models/thread.dart';
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

class _FakeThreadApi extends Fake implements HKGaldenApi {
  _FakeThreadApi(this._handler);
  final Future<Thread?> Function(int id, int page) _handler;

  @override
  Future<Thread?> getThreadQuery(int id, int page) => _handler(id, page);
}

void main() {
  group('ThreadListCubit append failure', () {
    blocTest<ThreadListCubit, ThreadListState>(
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
        return ThreadListCubit(api: api);
      },
      act: (cubit) async {
        cubit.load(channelId: 'bw', page: 1);
        await Future<void>.delayed(Duration.zero);
        cubit.load(channelId: 'bw', page: 2);
      },
      expect: () => [
        isA<ThreadListLoading>(),
        isA<ThreadListLoaded>(),
        isA<ThreadListAppending>(),
        isA<ThreadListLoaded>(),
      ],
      wait: const Duration(milliseconds: 50),
    );
  });

  group('ThreadCubit pagination failure', () {
    blocTest<ThreadCubit, ThreadState>(
      'restores previous ThreadLoaded instead of full-page ThreadError',
      build: () {
        final api = _FakeThreadApi((id, page) async {
          if (page == 1) {
            return Thread.initial();
          }
          return null;
        });
        return ThreadCubit(api: api);
      },
      act: (bloc) async {
        await bloc.request(threadId: 1, page: 1, isInitialLoad: true);
        await bloc.request(threadId: 1, page: 2, isInitialLoad: false);
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
