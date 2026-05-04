import 'package:belluga_now/infrastructure/dal/dao/invites/invite_contact_import_cache.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invite_contact_import_cache_entry.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invite_contact_import_cache_storage_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invite_contact_match_cache_dto.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeInviteContactImportCacheStorage
    implements InviteContactImportCacheStorageContract {
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
  test('invite contact import cache rehydrates large payloads after chunked write',
      () async {
    final storage = _FakeInviteContactImportCacheStorage();
    final cache = InviteContactImportCache(storage: storage);
    final entry = InviteContactImportCacheEntry(
      signature: 'sig-1',
      importedAt: DateTime.utc(2026, 5, 2, 12),
      matches: List.generate(
        300,
        (index) => InviteContactMatchCacheDto(
          contactHash: 'hash-$index',
          type: 'phone',
          userId: 'user-$index',
          receiverAccountProfileId: 'profile-$index',
          displayName: 'Contato $index',
          avatarUrl: null,
          profileExposureLevel: 'capped_profile',
          inviteableReasons: const <String>['contact_match'],
          isInviteable: true,
        ),
        growable: false,
      ),
    );

    await cache.write('tenant-user-scope', entry);

    final restored = await cache.read('tenant-user-scope');

    expect(restored, isNotNull);
    expect(restored!.signature, entry.signature);
    expect(restored.importedAt, entry.importedAt);
    expect(restored.matches.map((item) => item.contactHash), hasLength(300));
    expect(
      storage.values.containsKey(
        'invite_contact_import_cache_v2:tenant-user-scope',
      ),
      isTrue,
    );
  });

  test('invite contact import cache can read legacy single-key payload',
      () async {
    final storage = _FakeInviteContactImportCacheStorage();
    final cache = InviteContactImportCache(storage: storage);

    await storage.write(
      'invite_contact_import_cache_v1:tenant-user-scope',
      '{"signature":"legacy-signature","imported_at":"2026-05-02T12:00:00.000Z","matches":[{"contact_hash":"hash-1","type":"phone","user_id":"user-1","receiver_account_profile_id":"profile-1","display_name":"Contato legado","avatar_url":null,"profile_exposure_level":"capped_profile","inviteable_reasons":["contact_match"],"is_inviteable":true}]}',
    );

    final restored = await cache.read('tenant-user-scope');

    expect(restored, isNotNull);
    expect(restored!.signature, 'legacy-signature');
    expect(restored.matches.single.displayName, 'Contato legado');
  });
}
