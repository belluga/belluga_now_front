import 'dart:convert';

import 'package:belluga_now/infrastructure/dal/dao/invites/invite_contact_import_cache_contract.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class InviteContactImportCache implements InviteContactImportCacheContract {
  InviteContactImportCache({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _keyPrefix = 'invite_contact_import_cache_v1';

  final FlutterSecureStorage _storage;

  @override
  Future<InviteContactImportCacheEntry?> read(String cacheKey) async {
    try {
      final raw = await _storage.read(key: _storageKey(cacheKey));
      if (raw == null || raw.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }

      final signature = decoded['signature']?.toString().trim() ?? '';
      final importedAt = DateTime.tryParse(
        decoded['imported_at']?.toString() ?? '',
      );
      if (signature.isEmpty || importedAt == null) {
        return null;
      }

      return InviteContactImportCacheEntry(
        signature: signature,
        importedAt: importedAt,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(
    String cacheKey,
    InviteContactImportCacheEntry entry,
  ) async {
    try {
      await _storage.write(
        key: _storageKey(cacheKey),
        value: jsonEncode({
          'signature': entry.signature,
          'imported_at': entry.importedAt.toIso8601String(),
        }),
      );
    } catch (_) {
      // Import-cache persistence is an optimization. Contact import remains
      // correct when the cache cannot be written.
    }
  }

  String _storageKey(String cacheKey) => '$_keyPrefix:$cacheKey';
}
