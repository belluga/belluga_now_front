import 'dart:io';

import 'package:belluga_now/infrastructure/dal/dao/invites/invite_contact_import_cache_storage_contract.dart';
import 'package:path_provider/path_provider.dart';

class InviteContactImportCacheFileStorage
    implements InviteContactImportCacheStorageContract {
  InviteContactImportCacheFileStorage({
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider =
            directoryProvider ?? _defaultInviteContactImportCacheDirectory;

  final Future<Directory> Function() _directoryProvider;

  static Future<Directory> _defaultInviteContactImportCacheDirectory() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final cacheDirectory =
        Directory('${supportDirectory.path}/invite_contact_import_cache');
    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }
    return cacheDirectory;
  }

  @override
  Future<String?> read(String key) async {
    final file = await _resolveFile(key);
    if (!await file.exists()) {
      return null;
    }

    final raw = await file.readAsString();
    return raw.trim().isEmpty ? null : raw;
  }

  @override
  Future<void> write(String key, String value) async {
    final file = await _resolveFile(key);
    final temporaryFile = File('${file.path}.tmp');
    await temporaryFile.writeAsString(value, flush: true);
    if (await file.exists()) {
      await file.delete();
    }
    await temporaryFile.rename(file.path);
  }

  @override
  Future<void> delete(String key) async {
    final file = await _resolveFile(key);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _resolveFile(String key) async {
    final directory = await _directoryProvider();
    return File('${directory.path}/${Uri.encodeComponent(key)}.json');
  }
}
