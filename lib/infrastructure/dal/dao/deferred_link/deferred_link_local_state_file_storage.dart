import 'dart:io';

import 'package:belluga_now/infrastructure/dal/dao/deferred_link/deferred_link_local_state_storage_contract.dart';
import 'package:path_provider/path_provider.dart';

class DeferredLinkLocalStateFileStorage
    implements DeferredLinkLocalStateStorageContract {
  DeferredLinkLocalStateFileStorage({
    Future<Directory> Function()? directoryProvider,
  }) : _directoryProvider =
           directoryProvider ?? _defaultDeferredLinkLocalStateDirectory;

  final Future<Directory> Function() _directoryProvider;

  static Future<Directory> _defaultDeferredLinkLocalStateDirectory() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final localStateDirectory = Directory(
      '${supportDirectory.path}/deferred_link_local_state',
    );
    if (!await localStateDirectory.exists()) {
      await localStateDirectory.create(recursive: true);
    }
    return localStateDirectory;
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
