import 'package:hkgalden_flutter/bloc/cubit/compose_cubit.dart';
import 'package:hkgalden_flutter/bloc/cubit/compose_state.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/thread.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/models/user_group.dart';
import 'package:hkgalden_flutter/networking/hkgalden_api.dart';
import 'package:test/fake.dart';
import 'package:test/test.dart';

class _FakeApi extends Fake implements HKGaldenApi {
  _FakeApi({
    this.createThreadResult,
    this.sendReplyResult,
  });

  final int? createThreadResult;
  final Reply? sendReplyResult;

  final List<List<Object?>> createThreadCalls = [];
  final List<List<Object?>> sendReplyCalls = [];

  @override
  Future<int?> createThread(String title, List<String> tags, String html) async {
    createThreadCalls.add([title, tags, html]);
    return createThreadResult;
  }

  @override
  Future<Reply?> sendReply(int threadId, String html, {String? parentId}) async {
    sendReplyCalls.add([threadId, html, parentId]);
    return sendReplyResult;
  }

  @override
  Future<Thread?> getThreadQuery(int id, int page) async => null;
}

void main() {
  group('ComposeCubit', () {
    const galdenDeltaJson =
        '[{"insert":"hello","attributes":{"b":true}},{"insert":"\\n"}]';

    final sampleReply = Reply(
      floor: 2,
      author: const User(
        userId: '1',
        nickName: 'nick',
        avatar: '',
        userGroup: [UserGroup(groupId: 'g', groupName: 'n')],
        blockedUsers: [],
      ),
      authorNickname: 'nick',
      date: DateTime.utc(2024, 1, 1),
    );

    test('createThread uses real DeltaJsonParser and API with HTML', () async {
      final api = _FakeApi(createThreadResult: 7);
      final cubit = ComposeCubit(api: api);

      await cubit.createThread('主題', 'tagId', galdenDeltaJson);

      expect(api.createThreadCalls, hasLength(1));
      expect(api.createThreadCalls.single[0], '主題');
      expect(api.createThreadCalls.single[1], ['tagId']);
      final html = api.createThreadCalls.single[2] as String;
      expect(html, contains('hello'));
      expect(html, contains('data-nodetype'));
      expect(cubit.state, isA<ComposeSuccess>());
      expect((cubit.state as ComposeSuccess).result, 7);
      await cubit.close();
    });

    test('createThread emits failure when API returns null', () async {
      final api = _FakeApi(createThreadResult: null);
      final cubit = ComposeCubit(api: api);

      await cubit.createThread('t', 'tag', galdenDeltaJson);

      expect(cubit.state, isA<ComposeFailure>());
      expect((cubit.state as ComposeFailure).message, '主題發表失敗!');
      await cubit.close();
    });

    test('sendReply passes null parentId for normal reply (not empty string)',
        () async {
      final api = _FakeApi(sendReplyResult: sampleReply);
      final cubit = ComposeCubit(api: api);

      await cubit.sendReply(99, galdenDeltaJson);

      expect(api.sendReplyCalls, hasLength(1));
      expect(api.sendReplyCalls.single[0], 99);
      expect(api.sendReplyCalls.single[2], isNull);
      final html = api.sendReplyCalls.single[1] as String;
      expect(html, contains('hello'));
      expect(cubit.state, isA<ComposeSuccess>());
      expect((cubit.state as ComposeSuccess).result, sampleReply);
      await cubit.close();
    });

    test('sendReply passes parentId for quoted reply', () async {
      final api = _FakeApi(sendReplyResult: sampleReply);
      final cubit = ComposeCubit(api: api);

      await cubit.sendReply(99, galdenDeltaJson, parentId: 'parent-1');

      expect(api.sendReplyCalls.single[2], 'parent-1');
      await cubit.close();
    });

    test('sendReply emits failure when API returns null', () async {
      final api = _FakeApi(sendReplyResult: null);
      final cubit = ComposeCubit(api: api);

      await cubit.sendReply(1, galdenDeltaJson);

      expect(cubit.state, isA<ComposeFailure>());
      expect((cubit.state as ComposeFailure).message, '回覆發送失敗!');
      await cubit.close();
    });
  });
}
