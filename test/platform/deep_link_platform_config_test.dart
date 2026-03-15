import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android manifest declares guarappari app links', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(manifest, contains('android:autoVerify="true"'));
    expect(manifest, contains('android:host="guarappari.belluga.space"'));
    expect(manifest, contains('android:pathPrefix="/invite"'));
    expect(manifest, contains('android:pathPrefix="/convites"'));
  });

  test('iOS entitlements declare guarappari universal link domain', () {
    final entitlements =
        File('ios/Runner/Runner.entitlements').readAsStringSync();

    expect(entitlements, contains('com.apple.developer.associated-domains'));
    expect(entitlements, contains('applinks:guarappari.belluga.space'));
  });

  test('assetlinks is versioned with package mapping', () {
    final raw = File('.well-known/assetlinks.json').readAsStringSync();
    final decoded = jsonDecode(raw) as List<dynamic>;

    expect(decoded, isNotEmpty);
    final item = decoded.first as Map<String, dynamic>;
    final target = item['target'] as Map<String, dynamic>;

    expect(target['namespace'], 'android_app');
    expect(target['package_name'], 'com.guarappari.app');
    expect(
      (target['sha256_cert_fingerprints'] as List<dynamic>).isNotEmpty,
      isTrue,
    );
  });

  test('AASA is versioned with invite paths', () {
    final raw =
        File('.well-known/apple-app-site-association').readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final applinks = decoded['applinks'] as Map<String, dynamic>;
    final details = applinks['details'] as List<dynamic>;
    final firstDetail = details.first as Map<String, dynamic>;
    final paths = firstDetail['paths'] as List<dynamic>;

    expect(details, isNotEmpty);
    expect(paths, contains('/invite'));
    expect(paths, contains('/convites'));
  });

  test('nginx templates expose canonical .well-known routes', () {
    final prod =
        File('../docker/nginx/prod.conf.template').readAsStringSync();
    final local =
        File('../docker/nginx/local.conf.template').readAsStringSync();

    for (final template in [prod, local]) {
      expect(template, contains('location = /.well-known/assetlinks.json'));
      expect(
        template,
        contains('location = /.well-known/apple-app-site-association'),
      );
    }
  });

  test('laravel public well-known artifacts are versioned', () {
    final assetlinksRaw = File(
      '../laravel-app/public/.well-known/assetlinks.json',
    ).readAsStringSync();
    final aasaRaw = File(
      '../laravel-app/public/.well-known/apple-app-site-association',
    ).readAsStringSync();

    final assetlinks = jsonDecode(assetlinksRaw) as List<dynamic>;
    final assetlinksTarget =
        (assetlinks.first as Map<String, dynamic>)['target']
            as Map<String, dynamic>;
    final aasa = jsonDecode(aasaRaw) as Map<String, dynamic>;
    final aasaDetails =
        (aasa['applinks'] as Map<String, dynamic>)['details'] as List<dynamic>;

    expect(assetlinksTarget['package_name'], 'com.guarappari.app');
    expect(aasaDetails, isNotEmpty);
  });

  test('flutter and laravel well-known artifacts stay in sync', () {
    final flutterAssetlinks = jsonDecode(
      File('.well-known/assetlinks.json').readAsStringSync(),
    );
    final laravelAssetlinks = jsonDecode(
      File('../laravel-app/public/.well-known/assetlinks.json')
          .readAsStringSync(),
    );
    final flutterAasa = jsonDecode(
      File('.well-known/apple-app-site-association').readAsStringSync(),
    );
    final laravelAasa = jsonDecode(
      File('../laravel-app/public/.well-known/apple-app-site-association')
          .readAsStringSync(),
    );

    expect(laravelAssetlinks, flutterAssetlinks);
    expect(laravelAasa, flutterAasa);
  });
}
