import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android manifest declares guarappari app links', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(manifest, contains('android:autoVerify="true"'));
    expect(
      manifest,
      contains('android:name="flutter_deeplinking_enabled"'),
    );
    expect(manifest, contains('android:value="true"'));
    expect(manifest, contains('android:host="guarappari.belluga.space"'));
    for (final pathPrefix in const [
      '/invite',
      '/convites',
      '/agenda',
      '/agenda/evento',
      '/mapa',
      '/profile',
      '/home',
    ]) {
      expect(manifest, contains('android:pathPrefix="$pathPrefix"'));
    }
    expect(manifest, contains('android:path="/"'));
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
        contains(r'try_files $uri /index.php?$query_string;'),
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
