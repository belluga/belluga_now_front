import 'dart:io';

import 'package:belluga_now/infrastructure/dal/dao/contacts/contacts_local_cache_file_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('file storage persists payload across fresh storage instances', () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('contacts-local-cache-test');
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final writer = ContactsLocalCacheFileStorage(
      directoryProvider: () async => tempDirectory,
    );
    await writer.write('contacts_repository_cache_v2', '["cached"]');

    final reader = ContactsLocalCacheFileStorage(
      directoryProvider: () async => tempDirectory,
    );
    expect(
      await reader.read('contacts_repository_cache_v2'),
      '["cached"]',
    );
  });

  test('file storage delete removes persisted payload', () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('contacts-local-cache-delete');
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final storage = ContactsLocalCacheFileStorage(
      directoryProvider: () async => tempDirectory,
    );
    await storage.write('contacts_repository_cache_v2', '["cached"]');

    await storage.delete('contacts_repository_cache_v2');

    expect(await storage.read('contacts_repository_cache_v2'), isNull);
  });
}
