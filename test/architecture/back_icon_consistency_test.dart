import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('back controls use the canonical Icons.arrow_back glyph', () {
    final forbiddenTokens = <String>[
      'BackButton(',
      'BackButtonIcon(',
      'Icons.arrow_back_ios',
      'Icons.arrow_back_ios_new',
      'Icons.arrow_back_rounded',
      'Icons.chevron_left',
      'Icons.keyboard_arrow_left',
    ];
    final offenders = <String>[];

    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) {
        continue;
      }

      final source = file.readAsStringSync();
      for (final token in forbiddenTokens) {
        if (source.contains(token)) {
          offenders.add('${file.path}: $token');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Use IconButton/Icons.arrow_back for every back affordance.',
    );
  });
}
