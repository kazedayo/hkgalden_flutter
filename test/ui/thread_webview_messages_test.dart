import 'package:flutter_test/flutter_test.dart';
import 'package:hkgalden_flutter/ui/thread/webview/thread_webview_messages.dart';

void main() {
  test('parses known inbound type and payload', () {
    final message = ThreadWebViewInbound.tryParse(
      '{"type":"openLink","payload":{"url":"https://example.com"}}',
    );
    expect(message, isNotNull);
    expect(message!.type, 'openLink');
    expect(message.string('url'), 'https://example.com');
  });

  test('rejects unknown type', () {
    expect(
      ThreadWebViewInbound.tryParse('{"type":"eval","payload":{}}'),
      isNull,
    );
  });

  test('rejects malformed json', () {
    expect(ThreadWebViewInbound.tryParse('not-json'), isNull);
    expect(ThreadWebViewInbound.tryParse('[]'), isNull);
    expect(ThreadWebViewInbound.tryParse('{"payload":{}}'), isNull);
  });

  test('accepts contentReady', () {
    expect(
      ThreadWebViewInbound.tryParse('{"type":"contentReady"}')?.type,
      'contentReady',
    );
  });

  test('accepts contentHeight', () {
    final message = ThreadWebViewInbound.tryParse(
      '{"type":"contentHeight","payload":{"height":80}}',
    );
    expect(message?.type, 'contentHeight');
    expect(message?.integer('height'), 80);
  });

  test('treats missing payload as empty map', () {
    final message = ThreadWebViewInbound.tryParse('{"type":"ready"}');
    expect(message, isNotNull);
    expect(message!.payload, isEmpty);
  });

  test('coerces numeric payload fields', () {
    final message = ThreadWebViewInbound.tryParse(
      '{"type":"scroll","payload":{"y":12.5,"viewportTopFloor":3,"atEnd":true}}',
    );
    expect(message!.decimal('y'), 12.5);
    expect(message.integer('viewportTopFloor'), 3);
    expect(message.flag('atEnd'), isTrue);
    expect(message.flag('settled'), isFalse);
  });

  test('http(s) allow-list', () {
    expect(isHttpOrHttpsUrl('https://hkgalden.com'), isTrue);
    expect(isHttpOrHttpsUrl('http://example.com/a'), isTrue);
    expect(isHttpOrHttpsUrl('javascript:alert(1)'), isFalse);
    expect(isHttpOrHttpsUrl('file:///etc/passwd'), isFalse);
    expect(isHttpOrHttpsUrl('data:text/html,x'), isFalse);
  });
}
