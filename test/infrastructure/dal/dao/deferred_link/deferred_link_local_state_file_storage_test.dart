import 'dart:io';

import 'package:belluga_now/infrastructure/dal/dao/deferred_link/deferred_link_local_state_file_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory testDirectory;

  setUp(() async {
    testDirectory = await Directory.systemTemp.createTemp(
      'deferred_link_local_state_test_',
    );
  });

  tearDown(() async {
    if (await testDirectory.exists()) {
      await testDirectory.delete(recursive: true);
    }
  });

  test('write/read/delete roundtrip uses the configured directory', () async {
    final storage = DeferredLinkLocalStateFileStorage(
      directoryProvider: () async => testDirectory,
    );

    await storage.write('capture_key', 'first');
    expect(await storage.read('capture_key'), 'first');

    await storage.write('capture_key', 'second');
    expect(await storage.read('capture_key'), 'second');

    await storage.delete('capture_key');
    expect(await storage.read('capture_key'), isNull);
  });
}
