import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web index points favicon and manifest to dynamic branding routes', () {
    final html = File('web/index.html').readAsStringSync();

    expect(
      html,
      contains('<link id="favicon" rel="icon" href="/favicon.ico">'),
    );
    expect(
      html,
      contains('<link rel="manifest" href="/manifest.json">'),
    );
    expect(
      html,
      contains("url.searchParams.set('v', Date.now().toString());"),
    );
    expect(
      html,
      contains(
        '<link id="apple-touch-icon" rel="apple-touch-icon" href="/icon/icon-192x192.png">',
      ),
    );
    expect(html, isNot(contains('href="favicon.png"')));
  });

  test('web bootstrap cache-busts the main dart bundle with build sha', () {
    final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();

    expect(bootstrap, contains('window.__WEB_BUILD_SHA__'));
    expect(bootstrap, contains('build.mainJsPath'));
    expect(bootstrap, contains('main.dart.js'));
    expect(bootstrap, contains('encodeURIComponent(__bellugaBuildSha)'));
  });
}
