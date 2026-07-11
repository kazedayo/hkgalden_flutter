import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural checks that the iOS project is configured for simulator builds.
/// These assert on the shipped project files (real paths), not re-implemented logic.
void main() {
  final root = Directory.current.path;
  final pbx = File('$root/ios/Runner.xcodeproj/project.pbxproj');
  final pubspec = File('$root/pubspec.yaml');
  final env = File('$root/.env');
  final mainDart = File('$root/lib/main.dart');

  test('project.pbxproj exists and allows iphonesimulator', () {
    expect(pbx.existsSync(), isTrue, reason: 'ios project must exist');
    final content = pbx.readAsStringSync();
    // Must not restrict platforms to device-only.
    expect(
      content.contains('SUPPORTED_PLATFORMS = iphoneos;'),
      isFalse,
      reason:
          'SUPPORTED_PLATFORMS = iphoneos excludes the simulator; use '
          '"iphoneos iphonesimulator" instead',
    );
    // Profile/Release should explicitly list both platforms when set.
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

  test('.env is present and listed as a Flutter asset (startup dotenv.load)', () {
    expect(env.existsSync(), isTrue, reason: '.env required by dotenv.load()');
    final pub = pubspec.readAsStringSync();
    expect(pub.contains('.env'), isTrue, reason: 'pubspec must list .env asset');
  });


  test('iOS project uses Swift Package Manager (Flutter 3.44+ default)', () {
    final pbxContent = pbx.readAsStringSync();
    expect(
      pbxContent.contains('FlutterGeneratedPluginSwiftPackage'),
      isTrue,
      reason: 'project must reference FlutterGeneratedPluginSwiftPackage',
    );
    expect(
      pbxContent.contains('[CP] Check Pods Manifest.lock'),
      isFalse,
      reason: 'CocoaPods Check Manifest phase must be removed after SPM migration',
    );
    // Podfile removed when all plugins support SPM
    final podfile = File('$root/ios/Podfile');
    expect(podfile.existsSync(), isFalse, reason: 'pure SPM project has no Podfile');
  });

  test('lib/main.dart is the Flutter entry point and loads dotenv', () {
    expect(mainDart.existsSync(), isTrue);
    final src = mainDart.readAsStringSync();
    expect(src.contains('dotenv.load'), isTrue);
    expect(src.contains('runApp'), isTrue);
  });
}
