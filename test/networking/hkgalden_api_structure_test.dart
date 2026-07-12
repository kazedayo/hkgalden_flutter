import 'dart:io';

import 'package:test/test.dart';

/// Structural checks that the API refactor keeps GraphQL documents coherent
/// without hitting the network. Reads the shipped source of HKGaldenApi.
void main() {
  late String apiSource;

  setUpAll(() {
    final file = File('lib/networking/hkgalden_api.dart');
    expect(file.existsSync(), isTrue,
        reason: 'shipped API file must exist at lib/networking/hkgalden_api.dart');
    apiSource = file.readAsStringSync();
  });

  test('shared CommentFields / CommentsRecursive fragments defined once', () {
    // Single fragment definitions in _GqlFragments, referenced for thread + reply.
    expect('fragment CommentFields on Reply'.allMatches(apiSource).length, 1);
    expect('fragment CommentsRecursive on Reply'.allMatches(apiSource).length, 1);
    expect(apiSource.contains('_GqlFragments.commentFields'), isTrue);
    expect(apiSource.contains('_GqlFragments.commentsRecursive'), isTrue);
    // Both getThreadQuery and sendReply pull in the shared fragments.
    expect(apiSource.contains('getThreadQuery'), isTrue);
    expect(apiSource.contains('sendReply'), isTrue);
  });

  test('thread list field selection shared between channel and user lists', () {
    expect(apiSource.contains('threadListFields'), isTrue);
    expect(apiSource.contains('_GqlFragments.threadListFields'), isTrue);
    // Root fields still distinct.
    expect(apiSource.contains('threadsByChannel'), isTrue);
    expect(apiSource.contains('threadsByUser'), isTrue);
  });

  test('request plumbing uses shared _query / _mutate helpers', () {
    expect(apiSource.contains('Future<T?> _query<T>'), isTrue);
    expect(apiSource.contains('Future<T?> _mutate<T>'), isTrue);
    // Public methods should not re-implement hasException branching inline.
    final hasExceptionCount = 'hasException'.allMatches(apiSource).length;
    // Only inside the two helpers.
    expect(hasExceptionCount, 2);
  });

  test('GraphQLClient is injectable for shared-client usage', () {
    expect(apiSource.contains('HKGaldenApi({GraphQLClient? client})'), isTrue);
  });
}
