import 'package:bloc_test/bloc_test.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_cubit.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApi extends Fake implements HKGaldenApi {
  @override
  Future<Thread?> getThreadQuery(int threadId, int page) async =>
      Thread.initial();
}

void main() {
  group('ThreadCubit', () {
    late ThreadCubit threadCubit;

    final fixedDate = DateTime.utc(2024, 1, 1);
    final sampleReply = Reply(
      floor: 1,
      author: const User(
        userId: '1',
        nickName: 'nickName',
        avatar: 'avatar',
        groupId: 'groupId',
        blockedUsers: [],
      ),
      authorNickname: 'authorNickname',
      date: fixedDate,
    );

    setUp(() {
      threadCubit = ThreadCubit(api: _FakeApi());
    });

    test('initial state should be ThreadLoading', () {
      expect(threadCubit.state, ThreadLoading());
    });

    blocTest(
      'emits ThreadLoaded state when request is initial load',
      build: () => threadCubit,
      act: (ThreadCubit bloc) => bloc.request(
        threadId: 1,
        page: 1,
        isInitialLoad: true,
      ),
      expect: () => [isA<ThreadLoading>(), isA<ThreadLoaded>()],
    );

    blocTest(
      'emits new state when request w/ isInitialLoad = false',
      build: () => threadCubit,
      act: (ThreadCubit bloc) async {
        await bloc.request(threadId: 1, page: 1, isInitialLoad: true);
        await bloc.request(threadId: 1, page: 2, isInitialLoad: false);
      },
      expect: () => [
        ThreadLoading(),
        ThreadLoaded(
          thread: Thread.initial(),
          previousPages: Thread.initial(),
          currentPage: 1,
          endPage: 1,
        ),
        ThreadAppending(),
        ThreadLoaded(
          thread: Thread.initial(),
          previousPages: Thread.initial(),
          currentPage: 1,
          endPage: 2,
        ),
      ],
    );

    blocTest(
      'emits new state when appendReply is called',
      build: () => threadCubit,
      act: (ThreadCubit bloc) async {
        await bloc.request(threadId: 1, page: 1, isInitialLoad: true);
        bloc.appendReply(sampleReply);
      },
      expect: () => [
        ThreadLoading(),
        ThreadLoaded(
          thread: Thread.initial(),
          previousPages: Thread.initial(),
          currentPage: 1,
          endPage: 1,
        ),
        ThreadAppending(),
        ThreadLoaded(
          thread: Thread.initial().copyWith(replies: [sampleReply]),
          previousPages: Thread.initial(),
          currentPage: 1,
          endPage: 1,
        ),
      ],
    );
  });
}
