import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS release config centralizes app identity', () {
    final xcconfig =
        File('ios/Flutter/BellugaRelease.xcconfig').readAsStringSync();
    final debugConfig = File('ios/Flutter/Debug.xcconfig').readAsStringSync();
    final releaseConfig =
        File('ios/Flutter/Release.xcconfig').readAsStringSync();
    final project = File('ios/Runner.xcodeproj/project.pbxproj')
        .readAsStringSync();
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(xcconfig, contains('BELLUGA_IOS_DISPLAY_NAME=Guarappari'));
    expect(xcconfig, contains('BELLUGA_IOS_BUNDLE_IDENTIFIER=com.guarappari.app'));
    expect(debugConfig, contains('#include "BellugaRelease.xcconfig"'));
    expect(releaseConfig, contains('#include "BellugaRelease.xcconfig"'));

    expect(project, contains(r'PRODUCT_BUNDLE_IDENTIFIER = "$(BELLUGA_IOS_BUNDLE_IDENTIFIER)"'));
    expect(
      project,
      contains(
        r'PRODUCT_BUNDLE_IDENTIFIER = "$(BELLUGA_IOS_BUNDLE_IDENTIFIER).RunnerTests"',
      ),
    );
    expect(plist, contains(r'$(BELLUGA_IOS_DISPLAY_NAME)'));
    expect(plist, contains(r'$(BELLUGA_IOS_BUNDLE_NAME)'));

    expect(project, isNot(contains('com.example.flutterLaravelBackendBoilerplate')));
    expect(plist, isNot(contains('Flutter Laravel Backend Boilerplate')));
  });

  test('iOS release config declares shipped sensitive APIs and push runtime', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final entitlements =
        File('ios/Runner/Runner.entitlements').readAsStringSync();
    final podfile = File('ios/Podfile').readAsStringSync();
    final project = File('ios/Runner.xcodeproj/project.pbxproj')
        .readAsStringSync();

    expect(plist, contains('NSContactsUsageDescription'));
    expect(plist, contains('NSLocationWhenInUseUsageDescription'));
    expect(plist, contains('NSCameraUsageDescription'));
    expect(plist, contains('NSPhotoLibraryUsageDescription'));

    expect(plist, contains('UIBackgroundModes'));
    expect(plist, contains('<string>fetch</string>'));
    expect(plist, contains('<string>remote-notification</string>'));

    expect(plist, contains('LSApplicationQueriesSchemes'));
    for (final scheme in const [
      'comgooglemaps',
      'waze',
      'citymapper',
      'mapswithme',
      'mappls',
      'moovit',
    ]) {
      expect(plist, contains('<string>$scheme</string>'));
    }

    expect(entitlements, contains('aps-environment'));
    expect(entitlements, contains(r'$(BELLUGA_IOS_APS_ENVIRONMENT)'));
    expect(entitlements, contains('com.apple.developer.associated-domains'));
    expect(entitlements, contains('applinks:guarappari.com.br'));
    expect(entitlements, contains('applinks:guarappari.booraagora.com.br'));
    expect(entitlements, isNot(contains('applinks:guarappari.belluga.space')));

    expect(project, contains('com.apple.AssociatedDomains'));
    expect(project, contains('com.apple.BackgroundModes'));
    expect(project, contains('com.apple.Push'));
    expect(project, isNot(contains('BELLUGA_IOS_APS_ENVIRONMENT = development')));
    expect(project, contains('BELLUGA_IOS_APS_ENVIRONMENT = production'));

    expect(podfile, contains("platform :ios, '12.0'"));
    for (final macro in const [
      'PERMISSION_CONTACTS=1',
      'PERMISSION_CAMERA=1',
      'PERMISSION_PHOTOS=1',
      'PERMISSION_LOCATION=0',
      'PERMISSION_LOCATION_WHENINUSE=1',
    ]) {
      expect(podfile, contains(macro));
    }
    expect(podfile, isNot(contains('PERMISSION_MICROPHONE=1')));
    expect(podfile, isNot(contains('PERMISSION_NOTIFICATIONS=1')));
  });
}
