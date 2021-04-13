import 'package:bloc_test/bloc_test.dart';
import 'package:hkgalden_flutter/bloc/thread/thread_bloc.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/models/user_group.dart';
import 'package:hkgalden_flutter/repository/thread_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'thread_bloc_test.mocks.dart';

@GenerateMocks([ThreadRepository])
void main() {
  group('ThreadBloc', () {
    late ThreadRepository repository;
    late ThreadBloc threadBloc;

    setUp(() {
      repository = MockThreadRepository();
      when(repository.getThread(1, 1))
          .thenAnswer((_) async => Thread.initial());
      when(repository.getThread(1, 2))
          .thenAnswer((_) async => Thread.initial());
      threadBloc = ThreadBloc(repository: repository);
    });

    test('initial state should be ThreadLoading', () {
      expect(threadBloc.state, ThreadLoading());
    });

    blocTest('emits ThreadLoaded state when RequestThreadEvent added',
        build: () => threadBloc,
        act: (ThreadBloc bloc) => bloc.add(const RequestThreadEvent(
            threadId: 1, page: 1, isInitialLoad: true)),
        expect: () => [isA<ThreadLoaded>()],
        verify: (_) => verify(repository.getThread(1, 1)).called(1));

    blocTest(
        'emits new state when RequestThreadEvent w/ isInitialLoad = false added',
        build: () => threadBloc,
        act: (ThreadBloc bloc) => bloc
          ..add(const RequestThreadEvent(
              threadId: 1, page: 1, isInitialLoad: true))
          ..add(const RequestThreadEvent(
              threadId: 1, page: 2, isInitialLoad: false)),
        expect: () => [
              ThreadLoaded(
                  thread: Thread.initial(),
                  previousPages: Thread.initial(),
                  currentPage: 1,
                  endPage: 1),
              ThreadAppending(),
              ThreadLoaded(
                  thread: Thread.initial(),
                  previousPages: Thread.initial(),
                  currentPage: 2,
                  endPage: 2)
            ]);

    blocTest('emits new state when AppendReplyToThreadEvent added',
        build: () => threadBloc,
        act: (ThreadBloc bloc) => bloc
          ..add(const RequestThreadEvent(
              threadId: 1, page: 1, isInitialLoad: true))
          ..add(AppendReplyToThreadEvent(
              reply: Reply(
                  floor: 1,
                  author: const User(
                      userId: "1",
                      nickName: "nickName",
                      avatar: "avatar",
                      userGroup: [
                        UserGroup(groupId: "groupId", groupName: "groupName")
                      ],
                      blockedUsers: []),
                  authorNickname: "authorNickname",
                  date: DateTime.now()))),
        expect: () => [
              ThreadLoaded(
                  thread: Thread.initial().copyWith(replies: [
                    Reply(
                        floor: 1,
                        author: const User(
                            userId: "1",
                            nickName: "nickName",
                            avatar: "avatar",
                            userGroup: [
                              UserGroup(
                                  groupId: "groupId", groupName: "groupName")
                            ],
                            blockedUsers: []),
                        authorNickname: "authorNickname",
                        date: DateTime.now())
                  ]),
                  previousPages: Thread.initial(),
                  currentPage: 1,
                  endPage: 1)
            ]);
  });
}
