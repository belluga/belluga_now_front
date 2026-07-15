import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_avatar_bytes_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_display_name_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_email_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_id_value.dart';
import 'package:belluga_now/domain/contacts/value_objects/contact_phone_value.dart';
import 'package:belluga_now/domain/repositories/contacts_repository_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/contacts/contacts_local_cache.dart';
import 'package:belluga_now/infrastructure/dal/dao/contacts/contacts_local_cache_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:stream_value/core/stream_value.dart';

class ContactsRepository implements ContactsRepositoryContract {
  ContactsRepository({
    Future<bool> Function()? permissionRequester,
    Future<List<ContactModel>> Function()? deviceContactsLoader,
    ContactsLocalCacheContract? localCache,
  }) : this._internal(
         permissionRequester,
         deviceContactsLoader,
         localCache ?? ContactsLocalCache(),
       );

  ContactsRepository._internal(
    this._permissionRequester,
    this._deviceContactsLoader,
    this._localCache,
  );

  final Future<bool> Function()? _permissionRequester;
  final Future<List<ContactModel>> Function()? _deviceContactsLoader;
  final ContactsLocalCacheContract _localCache;

  @override
  final contactsStreamValue = StreamValue<List<ContactModel>?>(
    defaultValue: null,
  );

  @override
  Future<bool> requestPermission() async {
    final permissionRequester = _permissionRequester;
    if (permissionRequester != null) {
      return permissionRequester();
    }

    if (kIsWeb) {
      return false;
    }

    try {
      final status = await FlutterContacts.permissions.request(
        PermissionType.read,
      );
      return _isContactsPermissionGranted(status);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StateError('Failed to request contacts permission: $error'),
        stackTrace,
      );
    }
  }

  @override
  Future<List<ContactModel>> getContacts() async {
    final deviceContactsLoader = _deviceContactsLoader;
    if (deviceContactsLoader != null) {
      return deviceContactsLoader();
    }

    try {
      if (!await requestPermission()) {
        return const [];
      }

      final contacts = await FlutterContacts.getAll(
        properties: const <ContactProperty>{
          ContactProperty.phone,
          ContactProperty.email,
        },
      );

      return contacts
          .map(
            (c) => ContactModel(
              idValue: ContactIdValue(c.id ?? ''),
              displayNameValue: ContactDisplayNameValue(c.displayName ?? ''),
              phoneValues: c.phones
                  .map((phone) => ContactPhoneValue(raw: phone.number))
                  .toList(growable: false),
              emailValues: c.emails
                  .map((email) => ContactEmailValue(raw: email.address))
                  .toList(growable: false),
              avatarValue: ContactAvatarBytesValue(
                c.photo?.thumbnail ?? c.photo?.fullSize,
              ),
            ),
          )
          .toList(growable: false);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        StateError('Failed to load contacts: $error'),
        stackTrace,
      );
    }
  }

  static bool _isContactsPermissionGranted(PermissionStatus status) {
    return status == PermissionStatus.granted ||
        status == PermissionStatus.limited;
  }

  @override
  Future<void> initializeContacts() async {
    await refreshContacts();
  }

  @override
  Future<void> loadCachedContacts() async {
    final currentContacts = contactsStreamValue.value;
    if (currentContacts != null) {
      return;
    }

    final cachedContacts = await _localCache.read();
    if (cachedContacts != null) {
      contactsStreamValue.addValue(cachedContacts);
    }
  }

  @override
  Future<void> refreshCachedContacts() async {
    await loadCachedContacts();
    if (contactsStreamValue.value != null) {
      return;
    }

    await refreshContacts();
  }

  @override
  Future<void> refreshContacts() async {
    final contacts = await getContacts();
    await _localCache.write(contacts);
    contactsStreamValue.addValue(contacts);
  }

  @override
  Future<void> clearCurrentIdentityState() async {
    await _localCache.clear();
    contactsStreamValue.addValue(null);
  }
}
