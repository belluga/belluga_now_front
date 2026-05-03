import 'package:belluga_now/infrastructure/dal/dao/contacts/contacts_local_cache.dart';
import 'package:belluga_now/infrastructure/dal/dao/contacts/contacts_local_cache_storage_contract.dart';
import 'package:belluga_now/testing/domain_factories.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeContactsLocalCacheStorage
    implements ContactsLocalCacheStorageContract {
  final Map<String, String> values = <String, String>{};

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  test('contacts local cache rehydrates contacts after chunked write', () async {
    final storage = _FakeContactsLocalCacheStorage();
    final cache = ContactsLocalCache(storage: storage);
    final contacts = List.generate(
      250,
      (index) => buildContactModel(
        id: 'contact-$index',
        displayName: 'Contato $index',
        phones: <String>[
          '+55 27 99999-${index.toString().padLeft(4, '0')}',
        ],
        emails: <String>['contato$index@example.com'],
      ),
      growable: false,
    );

    await cache.write(contacts);

    final restored = await cache.read();

    expect(restored, isNotNull);
    expect(restored, contacts);
    expect(storage.values.containsKey('contacts_repository_cache_v2'), isTrue);
  });

  test('contacts local cache can read legacy single-key payload', () async {
    final storage = _FakeContactsLocalCacheStorage();
    final cache = ContactsLocalCache(storage: storage);
    final contacts = [
      buildContactModel(
        id: 'legacy-1',
        displayName: 'Contato legado',
        phones: const <String>['+55 27 99999-0001'],
      ),
    ];

    await storage.write(
      'contacts_repository_cache_v1',
      '[{"id":"legacy-1","display_name":"Contato legado","phones":["+55 27 99999-0001"],"emails":[]}]',
    );

    final restored = await cache.read();

    expect(restored, contacts);
  });
}
