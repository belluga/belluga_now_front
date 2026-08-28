import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('iOS queries exactly the approved external map schemes', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final querySchemes = RegExp(
      r'<key>LSApplicationQueriesSchemes</key>\s*<array>(.*?)</array>',
      dotAll: true,
    ).firstMatch(plist);

    expect(querySchemes, isNotNull);
    final schemes = RegExp(r'<string>([^<]+)</string>')
        .allMatches(querySchemes!.group(1)!)
        .map((match) => match.group(1))
        .toList(growable: false);
    expect(schemes, <String>['comgooglemaps', 'waze']);
  });

  test('Android removes the plugin-contributed Neshan package query', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(
      manifest,
      contains('xmlns:tools="http://schemas.android.com/tools"'),
    );
    final queries = RegExp(
      r'<queries\b[^>]*>(.*?)</queries>',
      dotAll: true,
    ).firstMatch(manifest);
    expect(queries, isNotNull);

    final neshanRemovalNodes = RegExp(r'<package\b[^>]*/>', dotAll: true)
        .allMatches(queries!.group(1)!)
        .where((match) {
          final node = match.group(0)!;
          return RegExp(
                r'android:name\s*=\s*["\x27]org\.rajman\.neshan\.traffic\.tehran\.navigator["\x27]',
              ).hasMatch(node) &&
              RegExp(r'tools:node\s*=\s*["\x27]remove["\x27]').hasMatch(node);
        })
        .toList(growable: false);

    expect(
      neshanRemovalNodes,
      hasLength(1),
      reason: 'The Neshan package query must be removed exactly once.',
    );
  });
}
