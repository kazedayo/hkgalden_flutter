import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory.current.path;
  final pbx = File('$root/ios/Runner.xcodeproj/project.pbxproj');
  final pubspec = File('$root/pubspec.yaml');
  final mainDart = File('$root/lib/main.dart');

  test('project.pbxproj exists and allows iphonesimulator', () {
    expect(pbx.existsSync(), isTrue, reason: 'ios project must exist');
    final content = pbx.readAsStringSync();
    expect(
      content.contains('SUPPORTED_PLATFORMS = iphoneos;'),
      isFalse,
      reason:
          'SUPPORTED_PLATFORMS = iphoneos excludes the simulator; use '
          '"iphoneos iphonesimulator" instead',
    );
    final platformLines = content
        .split('\n')
        .where((l) => l.contains('SUPPORTED_PLATFORMS'))
        .toList();
    for (final line in platformLines) {
      expect(
        line.contains('iphonesimulator'),
        isTrue,
        reason: 'SUPPORTED_PLATFORMS line must include iphonesimulator: $line',
      );
    }
  });

  test('iOS deployment target is at least 15.0 (Xcode 27 requirement)', () {
    final pbxContent = pbx.readAsStringSync();
    final targets = RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = ([0-9.]+);')
        .allMatches(pbxContent)
        .map((m) => double.parse(m.group(1)!))
        .toList();
    expect(targets, isNotEmpty);
    for (final t in targets) {
      expect(t, greaterThanOrEqualTo(15.0), reason: 'deployment target $t < 15');
    }
  });

  test('simulator xcconfigs exclude x86_64 (Xcode 27 lipo multi-arch workaround)', () {
    for (final name in ['Debug.xcconfig', 'Release.xcconfig']) {
      final cfg = File('$root/ios/Flutter/$name').readAsStringSync();
      expect(
        cfg.contains('EXCLUDED_ARCHS[sdk=iphonesimulator*]'),
        isTrue,
        reason: '$name must set EXCLUDED_ARCHS for simulator',
      );
      expect(cfg.contains('x86_64'), isTrue, reason: '$name should exclude x86_64');
    }
  });

  test('client id is compiled in; no .env needed', () {
    final api = File('$root/lib/networking/hkgalden_api.dart').readAsStringSync();
    expect(api.contains('String.fromEnvironment'), isFalse,
        reason: 'client id must be a compile-time constant, no dart-define');
    expect(File('$root/.env').existsSync(), isFalse,
        reason: '.env is no longer an input; do not reintroduce it');
  });

  test('lib/main.dart is the Flutter entry point', () {
    expect(mainDart.existsSync(), isTrue);
    final src = mainDart.readAsStringSync();
    expect(src.contains('dotenv'), isFalse);
    expect(src.contains('runApp'), isTrue);
  });
}
