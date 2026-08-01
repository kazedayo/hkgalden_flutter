import 'dart:io';

import 'package:test/test.dart';

void main() {
  late String apiSource;

  setUpAll(() {
    final file = File('lib/networking/hkgalden_api.dart');
    expect(file.existsSync(), isTrue,
        reason: 'shipped API file must exist at lib/networking/hkgalden_api.dart');
    apiSource = file.readAsStringSync();
  });

  test('shared CommentFields / CommentsRecursive fragments defined once', () {
    expect('fragment CommentFields on Reply'.allMatches(apiSource).length, 1);
    expect('fragment CommentsRecursive on Reply'.allMatches(apiSource).length, 1);
    expect(apiSource.contains('_GqlFragments.commentFields'), isTrue);
    expect(apiSource.contains('_GqlFragments.commentsRecursive'), isTrue);
    expect(apiSource.contains('getThreadQuery'), isTrue);
    expect(apiSource.contains('sendReply'), isTrue);
  });

  test('thread list field selection shared between channel and user lists', () {
    expect(apiSource.contains('threadListFields'), isTrue);
    expect(apiSource.contains('_GqlFragments.threadListFields'), isTrue);
    expect(apiSource.contains('threadsByChannel'), isTrue);
    expect(apiSource.contains('threadsByUser'), isTrue);
  });

  test('request plumbing uses shared _query / _mutate helpers', () {
    expect(apiSource.contains('Future<T?> _query<T>'), isTrue);
    expect(apiSource.contains('Future<T?> _mutate<T>'), isTrue);
    final hasExceptionCount = 'hasException'.allMatches(apiSource).length;
    expect(hasExceptionCount, 2);
  });

  test('GraphQLClient is injectable for shared-client usage', () {
    expect(apiSource.contains('HKGaldenApi({GraphQLClient? client})'), isTrue);
  });

  test('getThreadQuery uses networkOnly to avoid cross-page cache pollution',
      () {
    final getThreadStart = apiSource.indexOf('Future<Thread?> getThreadQuery');
    expect(getThreadStart, greaterThanOrEqualTo(0));
    final getThreadEnd = apiSource.indexOf(
        'Future<List<Thread>?> getThreadListQuery', getThreadStart);
    expect(getThreadEnd, greaterThan(getThreadStart));
    final getThreadBody = apiSource.substring(getThreadStart, getThreadEnd);
    expect(getThreadBody.contains('FetchPolicy.networkOnly'), isTrue);
  });

  test('getInstalledPacksQuery requests installedPacks with smiley fields', () {
    expect(apiSource.contains('getInstalledPacksQuery'), isTrue);
    expect(apiSource.contains('installedPacks'), isTrue);
    final start = apiSource.indexOf('getInstalledPacksQuery');
    expect(start, greaterThanOrEqualTo(0));
    final body = apiSource.substring(start);
    expect(body.contains('id'), isTrue);
    expect(body.contains('title'), isTrue);
    expect(body.contains('smilies'), isTrue);
    expect(body.contains('alt'), isTrue);
    expect(body.contains('width'), isTrue);
    expect(body.contains('height'), isTrue);
    expect(body.contains('SmileyPack.fromJson'), isTrue);
  });
}
