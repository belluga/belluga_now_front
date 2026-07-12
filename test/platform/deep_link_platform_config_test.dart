import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, String> parseProperties(String contents) {
    return Map.fromEntries(
      contents
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && !line.startsWith('#'))
          .map((line) => line.split('='))
          .where((parts) => parts.length >= 2)
          .map(
            (parts) => MapEntry(
              parts.first.trim(),
              parts.sublist(1).join('=').trim(),
            ),
          ),
    );
  }

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
    expect(gradle, contains('requireProperty'));
    expect(gradle, contains('Missing committed public flavor properties'));
    expect(gradle, contains('Missing signing properties for release flavor'));
    expect(gradle, contains('Missing keystore file for release flavor'));
    expect(gradle, contains('Incomplete Codemagic signing environment'));
    expect(gradle, contains('Missing Codemagic keystore file'));
    expect(gradle, contains('CM_KEYSTORE_PATH'));
    expect(gradle, contains('CM_KEYSTORE_PASSWORD'));
    expect(gradle, contains('CM_KEY_ALIAS'));
    expect(gradle, contains('CM_KEY_PASSWORD'));
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
      '/descobrir',
      '/mapa',
      '/location/permission',
      '/parceiro',
      '/privacy-policy',
      '/profile',
      '/home',
      '/static',
    ]) {
      expect(gradle, contains('"$pathPrefix"'));
    }
    expect(gradle, contains('appLinkRouteExactPaths'));
    expect(gradle, contains('"/"'));

    expect(gradle, isNot(contains('BELLUGA_APP_LINK_HOST')));
    expect(gradle, isNot(contains('manifestPlaceholders["appLinkHost"]')));
  });

  test('Android flavor docs keep the public and secret file contract explicit', () {
    final readme = File('README.md').readAsStringSync();
    final recovery =
        File('android/keystores/README.recovery.txt').readAsStringSync();

    for (final content in [readme, recovery]) {
      expect(
        content,
        contains('android/flavors/<flavor>.public.properties'),
      );
      expect(
        content,
        contains('android/keystores/<flavor>.signing.properties'),
      );
      expect(content, contains('android/keystores/<flavor>.jks'));
      expect(content, contains('CM_KEYSTORE_PATH'));
      expect(content, contains('CM_KEYSTORE_PASSWORD'));
      expect(content, contains('CM_KEY_ALIAS'));
      expect(content, contains('CM_KEY_PASSWORD'));
      expect(content.toLowerCase(), contains('fail'));
      expect(content.toLowerCase(), contains('closed'));
      expect(content, contains('applicationId'));
      expect(content, contains('appLinkHosts'));
    }

    expect(
      readme,
      contains('android/flavors/tenant.public.properties.example'),
    );
    expect(
      readme,
      contains('android/keystores/tenant.signing.properties.example'),
    );
    expect(
      recovery,
      contains('android/flavors/tenant.public.properties.example'),
    );
    expect(
      recovery,
      contains('android/keystores/tenant.signing.properties.example'),
    );
  });

  test('Android gitignore protects secret signing surfaces only', () {
    final gitignore = File('android/.gitignore').readAsStringSync();

    expect(gitignore, contains('/keystores/*.jks'));
    expect(gitignore, contains('/keystores/*.signing.properties'));
    expect(gitignore, isNot(contains('/flavors/*.public.properties')));
  });

  test('Android flavor contract files are versioned in git', () {
    final trackedFiles = [
      'android/flavors/alfredochaves.public.properties',
      'android/flavors/belluga.public.properties',
      'android/flavors/guarappari.public.properties',
      'android/flavors/tenant.public.properties.example',
      'android/keystores/README.recovery.txt',
      'android/keystores/tenant.signing.properties.example',
    ];

    for (final path in trackedFiles) {
      final result = Process.runSync('git', [
        'ls-files',
        '--error-unmatch',
        path,
      ]);
      expect(
        result.exitCode,
        0,
        reason: '$path must be versioned in git.',
      );
    }
  });

  test('Android committed flavor files keep required public properties versioned', () {
    final flavorsDir = Directory('android/flavors');
    final publicFiles =
        flavorsDir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.public.properties'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    expect(publicFiles, isNotEmpty);

    for (final file in publicFiles) {
      final properties = parseProperties(file.readAsStringSync());
      expect(
        properties['applicationId'],
        isNotNull,
        reason: '${file.path} must declare applicationId.',
      );
      expect(
        properties['applicationId']!,
        isNotEmpty,
        reason: '${file.path} must not leave applicationId blank.',
      );
      expect(
        properties['appLinkHosts'],
        isNotNull,
        reason: '${file.path} must declare appLinkHosts.',
      );
      expect(
        properties['appLinkHosts']!,
        isNotEmpty,
        reason: '${file.path} must not leave appLinkHosts blank.',
      );
    }
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
    expect(script, contains('/descobrir'));
    expect(script, contains('/privacy-policy'));
    expect(script, contains('/location/permission'));
    expect(script, contains('/parceiro'));
    expect(script, contains('/parceiro/profile-slug'));
    expect(script, contains('/static/praia-das-virtudes'));
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

  test('Android flavor contract verifier covers negative-path failures', () {
    final script =
        File('tool/verify_android_flavor_contract.sh').readAsStringSync();

    expect(script, contains('git ls-files --error-unmatch'));
    expect(script, contains('tenant.public.properties.example'));
    expect(script, contains('tenant.signing.properties.example'));
    expect(script, contains(r'assemble${task_flavor}Debug'));
    expect(script, contains(r'bundle${task_flavor}Release'));
    expect(script, contains('Missing committed public flavor properties'));
    expect(script, contains('applicationId'));
    expect(script, contains('appLinkHosts'));
    expect(script, contains('Missing signing properties for release flavor'));
    expect(script, contains('Missing keystore file for release flavor'));
    expect(script, contains('Incomplete Codemagic signing environment'));
    expect(script, contains('Missing Codemagic keystore file'));
    expect(script, contains('CM_KEYSTORE_PATH'));
    expect(script, contains('CM_KEYSTORE_PASSWORD'));
    expect(script, contains('CM_KEY_ALIAS'));
    expect(script, contains('CM_KEY_PASSWORD'));
  });

}
