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

  test('nginx templates expose canonical .well-known routes', () {
    final prod = File('../docker/nginx/prod.conf.template').readAsStringSync();
    final local =
        File('../docker/nginx/local.conf.template').readAsStringSync();

    for (final template in [prod, local]) {
      expect(template, contains('location = /.well-known/assetlinks.json'));
      expect(
        template,
        contains('location = /.well-known/apple-app-site-association'),
      );
      expect(
        template,
        contains(r'try_files /index.php?$query_string =404;'),
      );
    }
  });

  test('laravel public .well-known files are absent (endpoint is canonical)',
      () {
    final laravelAssetlinks = File(
      '../laravel-app/public/.well-known/assetlinks.json',
    );
    final laravelAasa = File(
      '../laravel-app/public/.well-known/apple-app-site-association',
    );

    expect(laravelAssetlinks.existsSync(), isFalse);
    expect(laravelAasa.existsSync(), isFalse);
  });

  test('flutter .well-known files are absent (endpoint is canonical)', () {
    final flutterAssetlinks = File('.well-known/assetlinks.json');
    final flutterAasa = File('.well-known/apple-app-site-association');

    expect(flutterAssetlinks.existsSync(), isFalse);
    expect(flutterAasa.existsSync(), isFalse);
  });

  test('gitignore rules block accidental static .well-known files', () {
    final flutterGitignore = File('.gitignore').readAsStringSync();
    final laravelGitignore =
        File('../laravel-app/.gitignore').readAsStringSync();

    expect(flutterGitignore, contains('.well-known/assetlinks.json'));
    expect(
        flutterGitignore, contains('.well-known/apple-app-site-association'));
    expect(
      laravelGitignore,
      contains('/public/.well-known/assetlinks.json'),
    );
    expect(
      laravelGitignore,
      contains('/public/.well-known/apple-app-site-association'),
    );
  });
}
