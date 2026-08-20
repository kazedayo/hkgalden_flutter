import 'package:bloc_test/bloc_test.dart';
import 'package:hkgalden_flutter/bloc/thread_list/thread_list_bloc.dart';
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
  group('ThreadListBloc', () {
    late _FakeApi api;
    late ThreadListBloc threadListBloc;

    setUp(() {
      api = _FakeApi();
      threadListBloc = ThreadListBloc(api: api);
    });

    test('initial state should be ThreadListInit', () {
      expect(threadListBloc.state, ThreadListInit());
    });

    blocTest('emits ThreadListLoaded state when RequestThreadListEvent added',
        build: () => threadListBloc,
        act: (ThreadListBloc bloc) => bloc.add(const RequestThreadListEvent(
            channelId: 'bw', page: 1, isRefresh: false)),
        expect: () => [isA<ThreadListLoading>(), isA<ThreadListLoaded>()]);

    blocTest('emits new state when RequestThreadListEvent w/ page > 1 added',
        build: () => threadListBloc,
        act: (ThreadListBloc bloc) => bloc
          ..add(const RequestThreadListEvent(
              channelId: 'bw', page: 1, isRefresh: false))
          ..add(const RequestThreadListEvent(
              channelId: 'bw', page: 2, isRefresh: false)),
        expect: () => [
              isA<ThreadListLoading>(),
              const ThreadListLoaded(
                  threads: [], currentChannelId: 'bw', currentPage: 1),
              isA<ThreadListAppending>(),
              const ThreadListLoaded(
                  threads: [], currentChannelId: 'bw', currentPage: 2)
            ]);

    blocTest('does not emit ThreadListLoading when refresh while loaded',
        build: () => threadListBloc,
        act: (ThreadListBloc bloc) async {
          bloc.add(const RequestThreadListEvent(
              channelId: 'bw', page: 1, isRefresh: false));
          await Future<void>.delayed(Duration.zero);
          bloc.add(const RequestThreadListEvent(
              channelId: 'bw', page: 1, isRefresh: true));
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
          return threadListBloc;
        },
        act: (ThreadListBloc bloc) async {
          bloc.add(const RequestThreadListEvent(
              channelId: 'bw', page: 1, isRefresh: false));
          await Future<void>.delayed(Duration.zero);
          bloc.add(const RequestThreadListEvent(
              channelId: 'bw', page: 2, isRefresh: false));
          bloc.add(const RequestThreadListEvent(
              channelId: 'bw', page: 2, isRefresh: false));
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
