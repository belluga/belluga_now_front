import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('InvitesRepository contact import has no client-side chunk request loop',
      () {
    final source =
        File('lib/infrastructure/repositories/invites_repository.dart')
            .readAsStringSync();
    final importBody = _methodBody(source, 'importContacts');

    expect(source, isNot(contains('_chunkContactImportItems')));
    expect(source, isNot(contains('_maxContactImportItemsPerRequest')));
    expect(importBody, isNot(contains('for (final chunk')));
    expect(importBody, isNot(contains('for (var chunk')));
    expect(
      RegExp(r'_backend\.importContacts\s*\(').allMatches(importBody),
      hasLength(1),
    );
    expect(
      RegExp(r'InviteContactImportRequest\s*\(').allMatches(importBody),
      hasLength(1),
    );
  });
}

String _methodBody(String source, String methodName) {
  final signature = RegExp(
    r'Future<List<InviteContactMatch>>\s+' + methodName + r'\s*\(',
  ).firstMatch(source);
  expect(signature, isNotNull);

  final bodyStart = source.indexOf('{', signature!.end);
  expect(bodyStart, isNonNegative);

  var depth = 0;
  for (var index = bodyStart; index < source.length; index += 1) {
    final char = source[index];
    if (char == '{') {
      depth += 1;
    } else if (char == '}') {
      depth -= 1;
      if (depth == 0) {
        return source.substring(bodyStart, index + 1);
      }
    }
  }

  fail('Could not locate $methodName body.');
}
