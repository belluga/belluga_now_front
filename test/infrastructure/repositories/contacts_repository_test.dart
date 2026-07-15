import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/infrastructure/dal/dao/contacts/contacts_local_cache_contract.dart';
import 'package:belluga_now/infrastructure/repositories/contacts_repository.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeContactsLocalCache implements ContactsLocalCacheContract {
  _FakeContactsLocalCache({this.cachedContacts});

  List<ContactModel>? cachedContacts;
  List<ContactModel>? writtenContacts;
  int clearCount = 0;
  int readCount = 0;
  int writeCount = 0;

  @override
  Future<List<ContactModel>?> read() async {
    readCount += 1;
    return cachedContacts;
  }

  @override
  Future<void> write(List<ContactModel> contacts) async {
    writeCount += 1;
    writtenContacts = contacts;
  }

  @override
  Future<void> clear() async {
    clearCount += 1;
    cachedContacts = null;
  }
}

void main() {
  test('requestPermission returns the injected permission result', () async {
    var permissionRequestCount = 0;
    final repository = ContactsRepository(
      permissionRequester: () async {
        permissionRequestCount += 1;
        return true;
      },
    );

    final granted = await repository.requestPermission();

    expect(granted, isTrue);
    expect(permissionRequestCount, 1);
  });

  test('getContacts returns an empty list when permission is denied', () async {
    final repository = ContactsRepository(
      permissionRequester: () async => false,
    );

    final contacts = await repository.getContacts();

    expect(contacts, isEmpty);
  });

  test('loadCachedContacts hydrates cache without device fallback', () async {
    var deviceLoadCount = 0;
    final cachedContact = buildContactModel(
      id: 'cached-1',
      displayName: 'Contato Cache',
      phones: const <String>['+55 27 99999-0001'],
    );
    final localCache = _FakeContactsLocalCache(cachedContacts: [cachedContact]);
    final repository = ContactsRepository(
      localCache: localCache,
      deviceContactsLoader: () async {
        deviceLoadCount += 1;
        return [
          buildContactModel(id: 'device-1', displayName: 'Contato Device'),
        ];
      },
    );

    await repository.loadCachedContacts();

    expect(repository.contactsStreamValue.value, [cachedContact]);
    expect(deviceLoadCount, 0);
    expect(localCache.readCount, 1);
    expect(localCache.writeCount, 0);
  });

  test('loadCachedContacts leaves stream empty when cache is empty', () async {
    var deviceLoadCount = 0;
    final localCache = _FakeContactsLocalCache();
    final repository = ContactsRepository(
      localCache: localCache,
      deviceContactsLoader: () async {
        deviceLoadCount += 1;
        return [
          buildContactModel(id: 'device-1', displayName: 'Contato Device'),
        ];
      },
    );

    await repository.loadCachedContacts();

    expect(repository.contactsStreamValue.value, isNull);
    expect(deviceLoadCount, 0);
    expect(localCache.readCount, 1);
    expect(localCache.writeCount, 0);
  });

  test(
    'refreshCachedContacts can hydrate from local cache without device reload',
    () async {
      var deviceLoadCount = 0;
      final cachedContact = buildContactModel(
        id: 'cached-1',
        displayName: 'Contato Cache',
        phones: const <String>['+55 27 99999-0001'],
      );
      final localCache = _FakeContactsLocalCache(
        cachedContacts: [cachedContact],
      );
      final repository = ContactsRepository(
        localCache: localCache,
        deviceContactsLoader: () async {
          deviceLoadCount += 1;
          return [
            buildContactModel(id: 'device-1', displayName: 'Contato Device'),
          ];
        },
      );

      await repository.refreshCachedContacts();

      expect(repository.contactsStreamValue.value, [cachedContact]);
      expect(deviceLoadCount, 0);
      expect(localCache.readCount, 1);
      expect(localCache.writeCount, 0);
    },
  );

  test(
    'refreshCachedContacts falls back to device and writes cache when empty',
    () async {
      var deviceLoadCount = 0;
      final deviceContact = buildContactModel(
        id: 'device-1',
        displayName: 'Contato Device',
        phones: const <String>['+55 27 99999-0002'],
      );
      final localCache = _FakeContactsLocalCache();
      final repository = ContactsRepository(
        localCache: localCache,
        deviceContactsLoader: () async {
          deviceLoadCount += 1;
          return [deviceContact];
        },
      );

      await repository.refreshCachedContacts();

      expect(repository.contactsStreamValue.value, [deviceContact]);
      expect(deviceLoadCount, 1);
      expect(localCache.readCount, 1);
      expect(localCache.writeCount, 1);
      expect(localCache.writtenContacts, [deviceContact]);
    },
  );

  test(
    'clearCurrentIdentityState clears stream and persistent cache',
    () async {
      final cachedContact = buildContactModel(
        id: 'cached-1',
        displayName: 'Contato Cache',
        phones: const <String>['+55 27 99999-0001'],
      );
      final localCache = _FakeContactsLocalCache(
        cachedContacts: [cachedContact],
      );
      final repository = ContactsRepository(localCache: localCache);

      repository.contactsStreamValue.addValue([cachedContact]);

      await repository.clearCurrentIdentityState();

      expect(repository.contactsStreamValue.value, isNull);
      expect(localCache.clearCount, 1);
      expect(localCache.cachedContacts, isNull);
    },
  );
}
