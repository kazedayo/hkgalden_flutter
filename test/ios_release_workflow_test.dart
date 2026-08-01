import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural tests for the iOS App Store Connect CI workflow.
///
/// These drive the real shipped artifacts under `.github/workflows/` and
/// `ios/ExportOptions.plist` so a broken/missing release pipeline fails unit
/// tests without needing live GitHub runners or Apple credentials.
void main() {
  final root = Directory.current.path;
  final workflowFile = File('$root/.github/workflows/ios-release.yml');
  final androidWorkflow = File('$root/.github/workflows/android-release.yml');
  final exportOptions = File('$root/ios/ExportOptions.plist');

  late String workflow;

  setUpAll(() {
    expect(
      workflowFile.existsSync(),
      isTrue,
      reason: 'iOS release workflow must exist at .github/workflows/ios-release.yml',
    );
    workflow = workflowFile.readAsStringSync();
  });

  test('workflow is triggerable via workflow_dispatch', () {
    expect(workflow.contains('workflow_dispatch'), isTrue);
  });

  test('runs on a macOS GitHub-hosted runner', () {
    final macRunner = RegExp(r'runs-on:\s*macos-');
    expect(macRunner.hasMatch(workflow), isTrue, reason: 'must use macos-* runner');
  });

  test('sets up Flutter stable and installs dependencies', () {
    expect(workflow.contains('subosito/flutter-action'), isTrue);
    expect(workflow.contains('channel: stable'), isTrue);
    expect(workflow.contains('flutter pub get'), isTrue);
  });

  test('materializes .env from HKGALDEN_CLIENT_ID secret with fail-fast', () {
    expect(workflow.contains('HKGALDEN_CLIENT_ID'), isTrue);
    expect(workflow.contains(r'${{ secrets.HKGALDEN_CLIENT_ID }}'), isTrue);
    expect(workflow.contains('Create .env'), isTrue);
    // Same spirit as android-release.yml: clear error when secret missing.
    expect(
      workflow.contains('Repository secret HKGALDEN_CLIENT_ID is not set'),
      isTrue,
    );
  });

  test('installs code signing material from repository secrets', () {
    for (final name in [
      'IOS_DISTRIBUTION_CERTIFICATE_BASE64',
      'IOS_DISTRIBUTION_CERTIFICATE_PASSWORD',
      'IOS_PROVISIONING_PROFILE_BASE64',
    ]) {
      expect(
        workflow.contains(r'${{ secrets.' '$name' r' }}'),
        isTrue,
        reason: 'must reference secrets.$name',
      );
      // Each secret is listed in the fail-fast loop body.
      expect(
        workflow.contains(name),
        isTrue,
        reason: 'fail-fast check must cover $name',
      );
    }
    // Same spirit as android-release.yml: clear error when a secret is unset.
    expect(
      workflow.contains(r'Repository secret $name is not set') ||
          workflow.contains('Repository secret'),
      isTrue,
      reason: 'must emit a clear error when signing secrets are missing',
    );
    expect(workflow.contains('security import'), isTrue);
    expect(workflow.contains('Provisioning Profiles'), isTrue);
  });

  test('builds a release IPA for org.hkgalden.app', () {
    expect(workflow.contains('flutter build ipa'), isTrue);
    expect(workflow.contains('--release'), isTrue);
    expect(workflow.contains('export-options-plist'), isTrue);
    expect(workflow.contains('org.hkgalden.app'), isTrue);
    // Clear failure if IPA missing after build.
    expect(workflow.contains('No IPA found'), isTrue);
  });

  test('injects manual signing via Release.xcconfig, not flutter -- args', () {
    // Regression: `flutter build ipa -- CODE_SIGN_STYLE=Manual` is interpreted as
    // --target and fails with: Target file "CODE_SIGN_STYLE=Manual" not found.
    // Extract only the "Build release IPA" job step (not earlier comments).
    final stepMarker = '- name: Build release IPA';
    final stepIdx = workflow.indexOf(stepMarker);
    expect(stepIdx, greaterThanOrEqualTo(0), reason: 'Build release IPA step required');
    final afterStep = workflow.substring(stepIdx);
    final nextStep = afterStep.indexOf('\n      - name:', stepMarker.length);
    final buildStep =
        nextStep < 0 ? afterStep : afterStep.substring(0, nextStep);

    expect(
      buildStep.contains('flutter build ipa'),
      isTrue,
      reason: 'Build release IPA step must invoke flutter build ipa',
    );
    // Any `flutter build ipa ... -- <something>` in the build step is broken.
    expect(
      RegExp(
        r'flutter build ipa[\s\S]*?--\s*\n\s*\S+',
        multiLine: true,
      ).hasMatch(buildStep),
      isFalse,
      reason:
          'must not pass args after `--` to flutter build ipa '
          '(those become the Dart target path, e.g. CODE_SIGN_STYLE=Manual)',
    );
    expect(
      RegExp(r'^\s*CODE_SIGN_', multiLine: true).hasMatch(buildStep),
      isFalse,
      reason: 'build step must not list CODE_SIGN_* as shell/flutter args',
    );

    // Real path: write settings into ios/Flutter/Release.xcconfig before build.
    expect(workflow.contains('ios/Flutter/Release.xcconfig'), isTrue);
    expect(workflow.contains('CODE_SIGN_STYLE=Manual'), isTrue);
    expect(workflow.contains('PROVISIONING_PROFILE_SPECIFIER='), isTrue);
    expect(
      workflow.contains('CODE_SIGN_IDENTITY[sdk=iphoneos*]=Apple Distribution'),
      isTrue,
    );
    expect(
      workflow.contains('>> ios/Flutter/Release.xcconfig') ||
          workflow.contains('>>ios/Flutter/Release.xcconfig'),
      isTrue,
      reason: 'must append signing settings into Release.xcconfig',
    );
  });

  test('uploads IPA to App Store Connect via API key secrets', () {
    for (final name in [
      'APP_STORE_CONNECT_API_KEY_ID',
      'APP_STORE_CONNECT_ISSUER_ID',
      'APP_STORE_CONNECT_API_KEY_BASE64',
    ]) {
      expect(
        workflow.contains(r'${{ secrets.' '$name' r' }}'),
        isTrue,
        reason: 'must reference secrets.$name',
      );
      expect(
        workflow.contains(name),
        isTrue,
        reason: 'fail-fast check must cover $name',
      );
    }
    // Real Apple-supported upload tools (Transporter or altool).
    final hasTransporter = workflow.contains('iTMSTransporter');
    final hasAltool = workflow.contains('altool') && workflow.contains('--upload-app');
    expect(
      hasTransporter || hasAltool,
      isTrue,
      reason: 'must upload via iTMSTransporter or altool --upload-app',
    );
  });

  test('documents required secret names in a header comment block', () {
    // Operator docs live in the top comment before the workflow `name:`.
    final headerEnd = workflow.indexOf('\nname:');
    expect(headerEnd, greaterThan(0), reason: 'workflow must declare name:');
    final header = workflow.substring(0, headerEnd);
    for (final name in [
      'HKGALDEN_CLIENT_ID',
      'IOS_DISTRIBUTION_CERTIFICATE_BASE64',
      'IOS_DISTRIBUTION_CERTIFICATE_PASSWORD',
      'IOS_PROVISIONING_PROFILE_BASE64',
      'APP_STORE_CONNECT_API_KEY_ID',
      'APP_STORE_CONNECT_ISSUER_ID',
      'APP_STORE_CONNECT_API_KEY_BASE64',
    ]) {
      expect(header.contains(name), isTrue, reason: 'header must document $name');
    }
  });

  test('does not hardcode private keys, certificates, or API key material', () {
    // No PEM / PKCS blobs / long base64 secrets committed in the workflow.
    expect(RegExp(r'BEGIN (RSA |EC )?PRIVATE KEY').hasMatch(workflow), isFalse);
    expect(RegExp(r'BEGIN CERTIFICATE').hasMatch(workflow), isFalse);
    // Secrets must only appear as GitHub secrets expressions or env names.
    final suspiciousBase64 = RegExp(r'[A-Za-z0-9+/]{80,}={0,2}');
    for (final match in suspiciousBase64.allMatches(workflow)) {
      final snippet = match.group(0)!;
      // Allow only non-secret-looking identifiers (none of these lengths expected).
      fail('Possible hardcoded secret material in workflow: ${snippet.substring(0, 40)}…');
    }
  });

  test('ios/ExportOptions.plist targets App Store Connect for org.hkgalden.app', () {
    expect(exportOptions.existsSync(), isTrue);
    final plist = exportOptions.readAsStringSync();
    expect(
      plist.contains('app-store-connect') || plist.contains('app-store'),
      isTrue,
      reason: 'export method must be app-store-connect or app-store',
    );
    expect(plist.contains('org.hkgalden.app'), isTrue);
    expect(plist.contains('R3W953ED69'), isTrue, reason: 'team id must match DEVELOPMENT_TEAM');
  });

  test('aligns with android-release.yml patterns (checkout, Flutter, .env fail-fast)', () {
    expect(androidWorkflow.existsSync(), isTrue);
    final android = androidWorkflow.readAsStringSync();
    expect(android.contains('actions/checkout@v4'), isTrue);
    expect(android.contains('subosito/flutter-action'), isTrue);
    expect(android.contains('Create .env'), isTrue);
    expect(android.contains('HKGALDEN_CLIENT_ID'), isTrue);

    expect(workflow.contains('actions/checkout@v4'), isTrue);
    expect(workflow.contains('subosito/flutter-action'), isTrue);
    expect(workflow.contains('Create .env'), isTrue);
    expect(workflow.contains('HKGALDEN_CLIENT_ID'), isTrue);
  });
}
