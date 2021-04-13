import 'package:bloc_test/bloc_test.dart';
import 'package:hkgalden_flutter/bloc/thread_list/thread_list_bloc.dart';
import 'package:hkgalden_flutter/repository/thread_list_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'thread_list_bloc_test.mocks.dart';

@GenerateMocks([ThreadListRepository])
void main() {
  group('ThreadListBloc', () {
    late ThreadListRepository repository;
    late ThreadListBloc threadListBloc;

    setUp(() {
      repository = MockThreadListRepository();
      when(repository.getThreadList('bw', 1)).thenAnswer((_) async => []);
      when(repository.getThreadList('bw', 2)).thenAnswer((_) async => []);
      threadListBloc = ThreadListBloc(repository: repository);
    });

    test('initial state should be ThreadListLoading', () {
      expect(threadListBloc.state, ThreadListLoading());
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
  });
}
