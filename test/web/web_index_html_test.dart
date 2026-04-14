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
}
