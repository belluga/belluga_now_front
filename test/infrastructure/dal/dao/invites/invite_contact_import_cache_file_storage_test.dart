import 'dart:io';

import 'package:belluga_now/infrastructure/dal/dao/invites/invite_contact_import_cache_file_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('file storage persists import-cache payload across fresh instances',
      () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'invite-contact-import-cache-test',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final writer = InviteContactImportCacheFileStorage(
      directoryProvider: () async => tempDirectory,
    );
    await writer.write('tenant-user-scope', '{"signature":"abc"}');

    final reader = InviteContactImportCacheFileStorage(
      directoryProvider: () async => tempDirectory,
    );
    expect(
      await reader.read('tenant-user-scope'),
      '{"signature":"abc"}',
    );
  });

  test('file storage delete removes persisted import-cache payload', () async {
    final tempDirectory = await Directory.systemTemp.createTemp(
      'invite-contact-import-cache-delete',
    );
    addTearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final storage = InviteContactImportCacheFileStorage(
      directoryProvider: () async => tempDirectory,
    );
    await storage.write('tenant-user-scope', '{"signature":"abc"}');

    await storage.delete('tenant-user-scope');

    expect(await storage.read('tenant-user-scope'), isNull);
  });
}
