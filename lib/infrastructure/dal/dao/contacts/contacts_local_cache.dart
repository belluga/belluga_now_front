import 'dart:convert';

import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_avatar_bytes_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_display_name_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_email_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_id_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_phone_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/contacts/contacts_local_cache_contract.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ContactsLocalCache implements ContactsLocalCacheContract {
  ContactsLocalCache({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _contactsCacheKey = 'contacts_repository_cache_v1';

  final FlutterSecureStorage _storage;

  @override
  Future<List<ContactModel>?> read() async {
    try {
      final raw = await _storage.read(key: _contactsCacheKey);
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
      await _storage.write(
        key: _contactsCacheKey,
        value: jsonEncode(
          contacts.map(_contactToCacheJson).toList(growable: false),
        ),
      );
    } catch (_) {
      // Contact cache is an optimization. Runtime contact loading remains
      // authoritative when persistence fails.
    }
  }

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
