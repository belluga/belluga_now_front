import 'dart:convert';

import 'package:belluga_now/infrastructure/dal/dao/invites/invite_contact_import_cache_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invite_contact_import_cache_file_storage.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invite_contact_match_cache_dto.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invite_contact_import_cache_storage_contract.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class _LegacyFlutterSecureStorageInviteContactImportCacheStorage
    implements InviteContactImportCacheStorageContract {
  _LegacyFlutterSecureStorageInviteContactImportCacheStorage({
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

class _CompositeInviteContactImportCacheStorage
    implements InviteContactImportCacheStorageContract {
  _CompositeInviteContactImportCacheStorage({
    InviteContactImportCacheStorageContract? primaryStorage,
    InviteContactImportCacheStorageContract? legacyStorage,
  })  : _primaryStorage =
            primaryStorage ?? InviteContactImportCacheFileStorage(),
        _legacyStorage = legacyStorage ??
            _LegacyFlutterSecureStorageInviteContactImportCacheStorage();

  final InviteContactImportCacheStorageContract _primaryStorage;
  final InviteContactImportCacheStorageContract _legacyStorage;

  @override
  Future<String?> read(String key) async {
    final primaryValue = await _primaryStorage.read(key);
    if (primaryValue != null && primaryValue.trim().isNotEmpty) {
      return primaryValue;
    }

    final legacyValue = await _legacyStorage.read(key);
    if (legacyValue != null && legacyValue.trim().isNotEmpty) {
      try {
        await _primaryStorage.write(key, legacyValue);
      } catch (_) {
        // Legacy fallback remains authoritative for this read when migration
        // to file-backed storage cannot complete yet.
      }
    }

    return legacyValue;
  }

  @override
  Future<void> write(String key, String value) => _primaryStorage.write(
        key,
        value,
      );

  @override
  Future<void> delete(String key) async {
    await _primaryStorage.delete(key);
    await _legacyStorage.delete(key);
  }
}

class InviteContactImportCache implements InviteContactImportCacheContract {
  InviteContactImportCache({InviteContactImportCacheStorageContract? storage})
      : _storage = storage ?? _CompositeInviteContactImportCacheStorage();

  static const String _keyPrefix = 'invite_contact_import_cache_v1';
  static const String _chunkedKeyPrefix = 'invite_contact_import_cache_v2';
  static const int _maxChunkChars = 24000;

  final InviteContactImportCacheStorageContract _storage;

  @override
  Future<InviteContactImportCacheEntry?> read(String cacheKey) async {
    try {
      final raw = await _readChunkedPayload(cacheKey) ?? await _storage.read(
            _storageKey(cacheKey),
          );
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
        matches: (() {
          final rawMatches = decoded['matches'];
          if (rawMatches is! List) {
            return const <InviteContactMatchCacheDto>[];
          }
          return rawMatches
              .whereType<Map>()
              .map((entry) => InviteContactMatchCacheDto.fromJsonMap(
                    Map<String, dynamic>.from(entry),
                  ))
              .toList(growable: false);
        })(),
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
      final encoded = jsonEncode({
        'signature': entry.signature,
        'imported_at': entry.importedAt.toIso8601String(),
        'matches': entry.matches.map((match) => match.toJsonMap()).toList(),
      });
      await _writeChunkedPayload(
        cacheKey: cacheKey,
        encoded: encoded,
      );
    } catch (_) {
      // Import-cache persistence is an optimization. Contact import remains
      // correct when the cache cannot be written.
    }
  }

  String _storageKey(String cacheKey) => '$_keyPrefix:$cacheKey';

  String _chunkMetaKey(String cacheKey) => '$_chunkedKeyPrefix:$cacheKey';

  String _chunkKey(String cacheKey, int index) => '${_chunkMetaKey(cacheKey)}:$index';

  Future<String?> _readChunkedPayload(String cacheKey) async {
    final rawMeta = await _storage.read(_chunkMetaKey(cacheKey));
    if (rawMeta == null || rawMeta.trim().isEmpty) {
      return null;
    }

    final decodedMeta = jsonDecode(rawMeta);
    if (decodedMeta is! Map) {
      return null;
    }

    final chunkCount = _parseChunkCount(decodedMeta['chunk_count']);
    if (chunkCount <= 0) {
      return null;
    }

    final buffer = StringBuffer();
    for (var index = 0; index < chunkCount; index += 1) {
      final chunk = await _storage.read(_chunkKey(cacheKey, index));
      if (chunk == null) {
        return null;
      }
      buffer.write(chunk);
    }

    final combined = buffer.toString();
    return combined.trim().isEmpty ? null : combined;
  }

  int _parseChunkCount(Object? raw) {
    if (raw is int) {
      return raw;
    }
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  Future<void> _writeChunkedPayload({
    required String cacheKey,
    required String encoded,
  }) async {
    final chunks = _splitIntoChunks(encoded);
    final previousMeta = await _storage.read(_chunkMetaKey(cacheKey));
    final previousChunkCount = previousMeta == null || previousMeta.trim().isEmpty
        ? 0
        : _parseChunkCount(
            (jsonDecode(previousMeta) as Map?)?['chunk_count'],
          );

    for (final entry in chunks.asMap().entries) {
      await _storage.write(_chunkKey(cacheKey, entry.key), entry.value);
    }
    await _storage.write(
      _chunkMetaKey(cacheKey),
      jsonEncode({'chunk_count': chunks.length}),
    );
    await _storage.delete(_storageKey(cacheKey));

    for (var index = chunks.length; index < previousChunkCount; index += 1) {
      await _storage.delete(_chunkKey(cacheKey, index));
    }
  }

  List<String> _splitIntoChunks(String encoded) {
    if (encoded.isEmpty) {
      return const <String>['{}'];
    }

    final chunks = <String>[];
    for (var start = 0; start < encoded.length; start += _maxChunkChars) {
      final end = (start + _maxChunkChars).clamp(0, encoded.length);
      chunks.add(encoded.substring(start, end));
    }
    return chunks;
  }
}
