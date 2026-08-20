import 'package:bloc_test/bloc_test.dart';
import 'package:hkgalden_flutter/bloc/thread_list/thread_list_cubit.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

class _FakeApi extends Fake implements HKGaldenApi {
  Duration? page2Delay;
  int page2Calls = 0;

  @override
  Future<List<Thread>?> getThreadListQuery(String channelId, int page) async {
    if (page == 2) {
      page2Calls++;
      final delay = page2Delay;
      if (delay != null) {
        await Future<void>.delayed(delay);
      }
    }
    return [];
  }
}

void main() {
  group('ThreadListCubit', () {
    late _FakeApi api;
    late ThreadListCubit cubit;

    setUp(() {
      api = _FakeApi();
      cubit = ThreadListCubit(api: api);
    });

    test('initial state should be ThreadListInit', () {
      expect(cubit.state, ThreadListInit());
    });

    blocTest('emits ThreadListLoaded when load page 1',
        build: () => cubit,
        act: (ThreadListCubit c) => c.load(channelId: 'bw', page: 1),
        expect: () => [isA<ThreadListLoading>(), isA<ThreadListLoaded>()]);

    blocTest('emits new state when load page > 1',
        build: () => cubit,
        act: (ThreadListCubit c) async {
          c.load(channelId: 'bw', page: 1);
          await Future<void>.delayed(Duration.zero);
          c.load(channelId: 'bw', page: 2);
        },
        expect: () => [
              isA<ThreadListLoading>(),
              const ThreadListLoaded(
                  threads: [], currentChannelId: 'bw', currentPage: 1),
              isA<ThreadListAppending>(),
              const ThreadListLoaded(
                  threads: [], currentChannelId: 'bw', currentPage: 2)
            ],
        wait: const Duration(milliseconds: 50));

    blocTest('does not emit ThreadListLoading when refresh while loaded',
        build: () => cubit,
        act: (ThreadListCubit c) async {
          c.load(channelId: 'bw', page: 1);
          await Future<void>.delayed(Duration.zero);
          c.load(channelId: 'bw', page: 1, isRefresh: true);
        },
        expect: () => [
              isA<ThreadListLoading>(),
              const ThreadListLoaded(
                  threads: [], currentChannelId: 'bw', currentPage: 1),
              const ThreadListLoaded(
                  threads: [],
                  currentChannelId: 'bw',
                  currentPage: 1,
                  generation: 1),
            ],
        wait: const Duration(milliseconds: 50));

    blocTest('ignores page > 1 while already appending',
        build: () {
          api.page2Delay = const Duration(milliseconds: 20);
          return cubit;
        },
        act: (ThreadListCubit c) async {
          c.load(channelId: 'bw', page: 1);
          await Future<void>.delayed(Duration.zero);
          c.load(channelId: 'bw', page: 2);
          c.load(channelId: 'bw', page: 2);
        },
        expect: () => [
              isA<ThreadListLoading>(),
              const ThreadListLoaded(
                  threads: [], currentChannelId: 'bw', currentPage: 1),
              isA<ThreadListAppending>(),
              const ThreadListLoaded(
                  threads: [], currentChannelId: 'bw', currentPage: 2)
            ],
        wait: const Duration(milliseconds: 50),
        verify: (_) {
          expect(api.page2Calls, 1);
        });
  });
}
