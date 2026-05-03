import 'dart:convert';

import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_avatar_bytes_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_display_name_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_email_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_id_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_phone_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/contacts/contacts_local_cache_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/contacts/contacts_local_cache_file_storage.dart';
import 'package:belluga_now/infrastructure/dal/dao/contacts/contacts_local_cache_storage_contract.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class _LegacyFlutterSecureStorageContactsLocalCacheStorage
    implements ContactsLocalCacheStorageContract {
  _LegacyFlutterSecureStorageContactsLocalCacheStorage({
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

class _CompositeContactsLocalCacheStorage
    implements ContactsLocalCacheStorageContract {
  _CompositeContactsLocalCacheStorage({
    ContactsLocalCacheStorageContract? primaryStorage,
    ContactsLocalCacheStorageContract? legacyStorage,
  })  : _primaryStorage = primaryStorage ?? ContactsLocalCacheFileStorage(),
        _legacyStorage = legacyStorage ??
            _LegacyFlutterSecureStorageContactsLocalCacheStorage();

  final ContactsLocalCacheStorageContract _primaryStorage;
  final ContactsLocalCacheStorageContract _legacyStorage;

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

class ContactsLocalCache implements ContactsLocalCacheContract {
  ContactsLocalCache({ContactsLocalCacheStorageContract? storage})
      : _storage = storage ?? _CompositeContactsLocalCacheStorage();

  static const String _contactsCacheKey = 'contacts_repository_cache_v1';
  static const String _contactsCacheMetaKey = 'contacts_repository_cache_v2';
  static const int _maxChunkChars = 24000;

  final ContactsLocalCacheStorageContract _storage;

  @override
  Future<List<ContactModel>?> read() async {
    try {
      final raw = await _readChunkedPayload() ?? await _storage.read(
            _contactsCacheKey,
          );
      if (raw == null || raw.trim().isEmpty) {
        return null;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return null;
      }

      return decoded
          .map(_contactFromCacheJson)
          .whereType<ContactModel>()
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(List<ContactModel> contacts) async {
    try {
      final encoded = jsonEncode(
        contacts.map(_contactToCacheJson).toList(growable: false),
      );
      await _writeChunkedPayload(encoded);
    } catch (_) {
      // Contact cache is an optimization. Runtime contact loading remains
      // authoritative when persistence fails.
    }
  }

  Future<String?> _readChunkedPayload() async {
    final rawMeta = await _storage.read(_contactsCacheMetaKey);
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
      final chunk = await _storage.read(_chunkKey(index));
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

  Future<void> _writeChunkedPayload(String encoded) async {
    final chunks = _splitIntoChunks(encoded);
    final previousMeta = await _storage.read(_contactsCacheMetaKey);
    final previousChunkCount = previousMeta == null || previousMeta.trim().isEmpty
        ? 0
        : _parseChunkCount(
            (jsonDecode(previousMeta) as Map?)?['chunk_count'],
          );

    for (final entry in chunks.asMap().entries) {
      await _storage.write(_chunkKey(entry.key), entry.value);
    }
    await _storage.write(
      _contactsCacheMetaKey,
      jsonEncode({'chunk_count': chunks.length}),
    );
    await _storage.delete(_contactsCacheKey);

    for (var index = chunks.length; index < previousChunkCount; index += 1) {
      await _storage.delete(_chunkKey(index));
    }
  }

  List<String> _splitIntoChunks(String encoded) {
    if (encoded.isEmpty) {
      return const <String>['[]'];
    }

    final chunks = <String>[];
    for (var start = 0; start < encoded.length; start += _maxChunkChars) {
      final end = (start + _maxChunkChars).clamp(0, encoded.length);
      chunks.add(encoded.substring(start, end));
    }
    return chunks;
  }

  String _chunkKey(int index) => '$_contactsCacheMetaKey:$index';

  Map<String, Object?> _contactToCacheJson(ContactModel contact) => {
        'id': contact.id,
        'display_name': contact.displayName,
        'phones': contact.phones.map((phone) => phone.value).toList(),
        'emails': contact.emails.map((email) => email.value).toList(),
      };

  ContactModel? _contactFromCacheJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }

    final id = raw['id']?.toString().trim() ?? '';
    final displayName = raw['display_name']?.toString().trim() ?? '';
    final phones = _stringList(raw['phones']);
    final emails = _stringList(raw['emails']);

    if (id.isEmpty && displayName.isEmpty && phones.isEmpty && emails.isEmpty) {
      return null;
    }

    return ContactModel(
      idValue: ContactIdValue(id),
      displayNameValue: ContactDisplayNameValue(displayName),
      phoneValues:
          phones.map((phone) => ContactPhoneValue(raw: phone)).toList(),
      emailValues:
          emails.map((email) => ContactEmailValue(raw: email)).toList(),
      avatarValue: ContactAvatarBytesValue(),
    );
  }

  List<String> _stringList(Object? raw) {
    if (raw is! List) {
      return const <String>[];
    }

    return raw
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }
}
