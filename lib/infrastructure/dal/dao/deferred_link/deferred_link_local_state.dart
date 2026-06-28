import 'package:belluga_now/infrastructure/dal/dao/deferred_link/deferred_link_local_state_file_storage.dart';
import 'package:belluga_now/infrastructure/dal/dao/deferred_link/deferred_link_local_state_storage_contract.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class _LegacyFlutterSecureStorageDeferredLinkLocalStateStorage
    implements DeferredLinkLocalStateStorageContract {
  _LegacyFlutterSecureStorageDeferredLinkLocalStateStorage({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class DeferredLinkLocalStateStorage
    implements DeferredLinkLocalStateStorageContract {
  DeferredLinkLocalStateStorage({
    DeferredLinkLocalStateStorageContract? primaryStorage,
    FlutterSecureStorage? legacyStorage,
  }) : _primaryStorage = primaryStorage ?? DeferredLinkLocalStateFileStorage(),
       _legacyStorage =
           _LegacyFlutterSecureStorageDeferredLinkLocalStateStorage(
             storage: legacyStorage,
           );

  final DeferredLinkLocalStateStorageContract _primaryStorage;
  final DeferredLinkLocalStateStorageContract _legacyStorage;

  @override
  Future<String?> read(String key) async {
    final primaryValue = await _primaryStorage.read(key);
    if (_hasValue(primaryValue)) {
      return primaryValue;
    }

    final legacyValue = await _legacyStorage.read(key);
    if (!_hasValue(legacyValue)) {
      return null;
    }

    try {
      await _primaryStorage.write(key, legacyValue!);
      await _legacyStorage.delete(key);
    } catch (_) {
      // When migration fails, the legacy value remains authoritative for this
      // read so first-open gating still behaves correctly.
    }

    return legacyValue;
  }

  @override
  Future<void> write(String key, String value) async {
    await _primaryStorage.write(key, value);
    try {
      await _legacyStorage.delete(key);
    } catch (_) {
      // Install-scoped storage is authoritative after the primary write.
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _primaryStorage.delete(key);
    } finally {
      await _legacyStorage.delete(key);
    }
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
}
