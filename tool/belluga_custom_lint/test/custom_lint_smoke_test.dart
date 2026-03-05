import 'dart:io';

import 'package:test/test.dart';

void main() {
  final fixtureDir = Directory(
    'test_fixtures/lint_matrix',
  );

  Future<ProcessResult> run(
    List<String> command, {
    required String workingDirectory,
  }) {
    return Process.run(
      command.first,
      command.sublist(1),
      workingDirectory: workingDirectory,
      runInShell: false,
    );
  }

  setUpAll(() async {
    final pubGet = await run(
      ['dart', 'pub', 'get'],
      workingDirectory: fixtureDir.path,
    );

    expect(pubGet.exitCode, 0, reason: '${pubGet.stdout}\n${pubGet.stderr}');
  });

  test('fixture expect_lint matrix stays satisfied', () async {
    final result = await run(
      ['dart', 'run', 'custom_lint'],
      workingDirectory: fixtureDir.path,
    );

    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
