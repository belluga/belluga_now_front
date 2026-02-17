import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('codebase uses AutoRoute navigation APIs instead of Navigator', () {
    final violations = <String>[];
    final roots = <String>['lib', 'test', 'integration_test'];

    for (final root in roots) {
      final directory = Directory(root);
      if (!directory.existsSync()) {
        continue;
      }
      for (final entity in directory.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) {
          continue;
        }
        if (_shouldIgnore(entity.path)) {
          continue;
        }
        final content = entity.readAsStringSync();
        if (_containsDirectNavigatorUsage(content)) {
          violations.add(entity.path);
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: violations.isEmpty
          ? null
          : 'Direct Navigator usage found in:\n${violations.join('\n')}',
    );
  });
}

bool _containsDirectNavigatorUsage(String content) {
  final patterns = <RegExp>[
    RegExp(r'Navigator\.of\('),
    RegExp(
      r'Navigator\.(push|pop|maybePop|pushNamed|pushReplacement|popUntil)\(',
    ),
  ];
  for (final pattern in patterns) {
    if (pattern.hasMatch(content)) {
      return true;
    }
  }
  return false;
}

bool _shouldIgnore(String path) {
  return path
      .endsWith('test/architecture/autoroute_navigation_guardrail_test.dart');
}
