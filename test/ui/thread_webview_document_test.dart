import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/bloc/session_user/session_user_bloc.dart';
import 'package:hkgalden_flutter/models/reply.dart';
import 'package:hkgalden_flutter/models/user.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview_document.dart';

void main() {
  const document = ThreadWebViewDocument(aspectRatioFor: _noRatio);

  test('applies hex color as inline style', () {
    final html = document.rewriteContentHtml(
      '<span class="color" hex="#ff0000">x</span>',
    ).html;
    expect(html, contains('color:#ff0000'));
    expect(html, contains('x'));
  });

  test('ignores invalid hex values', () {
    final html = document.rewriteContentHtml(
      '<span class="color" hex="javascript:alert(1)">x</span>',
    ).html;
    expect(html, isNot(contains('color:javascript')));
    expect(html, isNot(contains('style=')));
    expect(html, contains('x'));
  });

  test('converts icon tags to smiley images', () {
    final html = document.rewriteContentHtml(
      '<icon src="https://s.hkgalden.org/smilies/hkg/abc.gif"></icon>',
    ).html;
    expect(html, contains('class="smiley"'));
    expect(html, contains('https://s.hkgalden.org/smilies/hkg/abc.gif'));
    expect(html, isNot(contains('<icon')));
  });

  test('quoted images reserve the same box as top-level images', () {
    final html = document.rewriteContentHtml(
      '<blockquote><div class="quoteName">Nick 說:</div>'
      '<img src="https://example.com/a.png" data-sx="800" data-sy="200">'
      '</blockquote>',
    ).html;
    expect(html, contains('content-img'));
    expect(html, contains('aspect-ratio:800 / 200'));
    expect(html, contains('min(100%,800px)'));
  });

  test('reserves image box from data-sx/sy', () {
    final html = document.rewriteContentHtml(
      '<img src="https://example.com/a.png" data-sx="100" data-sy="50">',
    ).html;
    expect(html, contains('content-img'));
    expect(html, contains('aspect-ratio:100 / 50'));
    expect(html, contains('min(100%,100px)'));
  });

  test('uses cached aspect when dimensions are missing', () {
    final html = const ThreadWebViewDocument(
      aspectRatioFor: _halfRatio,
    ).rewriteContentHtml('<img src="https://example.com/a.png">').html;
    expect(html, contains('content-img'));
    expect(html, contains('aspect-ratio:2.00000'));
  });

  test('wraps YouTube links with preview placeholder', () {
    final html = document.rewriteContentHtml(
      '<a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ">yt</a>',
    ).html;
    expect(html, contains('data-preview="youtube"'));
    expect(html, contains('dQw4w9WgXcQ'));
    expect(html, contains('preview-chip'));
    expect(html, contains('yt'));
  });

  test('wraps X status links with preview placeholder', () {
    final html = document.rewriteContentHtml(
      '<a href="https://x.com/foo/status/1234567890123456789">post</a>',
    ).html;
    expect(html, contains('data-preview="x"'));
    expect(html, contains('1234567890123456789'));
    expect(html, contains('post'));
  });

  test('serializeReply stores YouTube and X ids from the rewrite pass', () {
    final reply = Reply(
      replyId: 'r1',
      floor: 1,
      content: '<a href="https://www.youtube.com/watch?v=dQw4w9WgXcQ">yt</a>'
          '<a href="https://x.com/foo/status/1234567890123456789">post</a>',
      author: const User(
        userId: 'u1',
        nickName: 'nick',
        avatar: '',
        userGroup: [],
        blockedUsers: [],
      ),
      authorNickname: 'nick',
      date: DateTime.utc(2024, 1, 1),
    );
    final dto = document.serializeReply(reply, SessionUserUndefined());
    expect(dto.youtubeIds, ['dQw4w9WgXcQ']);
    expect(dto.xIds, ['1234567890123456789']);
    expect(dto.html, contains('data-preview="youtube"'));
    expect(dto.html, contains('data-preview="x"'));
    expect(dto.toJson().containsKey('youtubeIds'), isFalse);
    expect(dto.toJson().containsKey('xIds'), isFalse);
  });
}

double? _noRatio(String url) => null;

double? _halfRatio(String url) => 0.5;
