import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android main manifest keeps app link hosts out of source XML', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(
      manifest,
      contains('android:name="flutter_deeplinking_enabled"'),
    );
    expect(manifest, contains('android:value="true"'));
    expect(manifest, isNot(contains('android:autoVerify="true"')));
    expect(manifest, isNot(contains('android:host="*"')));
    expect(manifest, isNot(contains('android:host="guarappari.belluga.space"')));
    expect(manifest, isNot(contains('android:host="guarappari.com.br"')));
    expect(manifest, isNot(contains(r'android:host="${appLinkHost}"')));
  });

  test('Android Gradle generates app link manifests from flavor hosts', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(gradle, contains('appLinkHosts'));
    expect(gradle, contains('normalizeAppLinkHosts'));
    expect(gradle, contains('generateAppLinksManifest'));
    expect(gradle, contains('sourceSets'));
    expect(gradle, contains('generated/app-link-manifests'));
    expect(gradle, contains('android:autoVerify="true"'));
    expect(gradle, contains('android:scheme="https"'));
    expect(gradle, isNot(contains('android:host="*"')));
    expect(gradle, isNot(contains('guarappari.belluga.space')));
    expect(gradle, isNot(contains('guarappari.com.br')));
    expect(gradle, isNot(contains(r'android:host="${appLinkHost}"')));

    for (final pathPrefix in const [
      '/invite',
      '/convites',
      '/agenda',
      '/agenda/evento',
      '/mapa',
      '/parceiro',
      '/profile',
      '/home',
    ]) {
      expect(gradle, contains('"$pathPrefix"'));
    }
    expect(gradle, contains('appLinkRouteExactPaths'));
    expect(gradle, contains('"/"'));

    expect(gradle, isNot(contains('BELLUGA_APP_LINK_HOST')));
    expect(gradle, isNot(contains('manifestPlaceholders["appLinkHost"]')));
  });

  test('Android device intent validation script queries merged app links', () {
    final script =
        File('tool/validate_android_app_link_intents.sh').readAsStringSync();

    expect(script, contains('ANDROID_APP_LINK_HOSTS'));
    expect(script, contains('ANDROID_OPEN_APP_BASE_URL'));
    expect(script, contains('ANDROID_MERGED_MANIFEST'));
    expect(script, contains('cmd package query-activities'));
    expect(script, contains('android.intent.action.VIEW'));
    expect(script, contains('android.intent.category.BROWSABLE'));
    expect(script, contains('/open-app'));
    expect(script, contains('intent://'));
    expect(script, contains('/parceiro'));
    expect(script, contains('/parceiro/profile-slug'));
    expect(script, contains('/agenda/evento/show-rock?occurrence=occ-1'));
    expect(script, contains('tenant.example.com'));
    expect(script, contains('android:host="\\*"'));
  });

  test('Android MainActivity refreshes warm app-link intents', () {
    final activity = File(
      'android/app/src/main/kotlin/com/example/flutter_laravel_backend_boilerplate/MainActivity.kt',
    ).readAsStringSync();

    expect(activity, contains('override fun onNewIntent(intent: Intent)'));
    expect(activity, contains('super.onNewIntent(intent)'));
    expect(activity, contains('setIntent(intent)'));
  });

  test('iOS entitlements declare guarappari production universal link domains', () {
    final entitlements =
        File('ios/Runner/Runner.entitlements').readAsStringSync();

    expect(entitlements, contains('com.apple.developer.associated-domains'));
    expect(entitlements, contains('applinks:guarappari.com.br'));
    expect(entitlements, contains('applinks:guarappari.booraagora.com.br'));
    expect(entitlements, isNot(contains('applinks:guarappari.belluga.space')));
    expect(entitlements, isNot(contains('applinks:guarappari.belluga.app')));
  });

  test('flutter .well-known files are absent (endpoint is canonical)', () {
    final flutterAssetlinks = File('.well-known/assetlinks.json');
    final flutterAasa = File('.well-known/apple-app-site-association');

    expect(flutterAssetlinks.existsSync(), isFalse);
    expect(flutterAasa.existsSync(), isFalse);
  });

  test('flutter gitignore rules block accidental static .well-known files', () {
    final flutterGitignore = File('.gitignore').readAsStringSync();

    expect(flutterGitignore, contains('.well-known/assetlinks.json'));
    expect(
        flutterGitignore, contains('.well-known/apple-app-site-association'));
  });
}
