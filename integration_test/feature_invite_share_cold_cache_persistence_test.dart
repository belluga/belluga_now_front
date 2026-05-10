import 'dart:async';

import 'package:belluga_now/application/invites/invite_contact_import_hashes.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/contacts/contact_model.dart';
import 'package:belluga_now/domain/invites/invite_model.dart';
import 'package:belluga_now/domain/repositories/invites_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/invite_contact_region_code_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/contacts/contacts_local_cache.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invite_contact_import_cache.dart';
import 'package:belluga_now/infrastructure/dal/dao/invites/invites_backend_requests.dart';
import 'package:belluga_now/infrastructure/dal/dto/invites/invite_realtime_delta_dto.dart';
import 'package:belluga_now/infrastructure/repositories/contacts_repository.dart';
import 'package:belluga_now/infrastructure/repositories/invites_repository.dart';
import 'package:belluga_now/infrastructure/services/invites_backend_contract.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/controllers/invite_share_screen_controller.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/invite_share_screen.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_external_contact_card.dart';
import 'package:belluga_now/presentation/tenant_public/invites/screens/invite_share_screen/widgets/invite_share_friend_card.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/testing/invite_model_factory.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:integration_test/integration_test.dart';

import 'support/integration_test_bootstrap.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  IntegrationTestBootstrap.ensureNonProductionLandlordDomain();

  setUp(() async {
    await GetIt.I.reset();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets(
    'invite share cold relaunch rehydrates app and Agenda panes from chunked local cache on device',
    (tester) async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.localeTestValue = const Locale('pt', 'BR');
      addTearDown(binding.platformDispatcher.clearLocaleTestValue);

      const viewerId = 'cold-cache-viewer';
      const tenantScope = 'cold-cache-tenant';
      final now = DateTime.utc(2026, 5, 2, 12);

      final primingContactsRepository = ContactsRepository(
        localCache: ContactsLocalCache(),
      );
      expect(
        await primingContactsRepository.requestPermission(),
        isTrue,
        reason: 'Device cold-cache validation requires contacts permission.',
      );
      await primingContactsRepository.refreshContacts();
      final allContacts = (primingContactsRepository.contactsStreamValue.value ??
              const <ContactModel>[])
          .where((contact) => contact.phones.isNotEmpty || contact.emails.isNotEmpty)
          .toList(growable: false);
      expect(
        allContacts.length,
        greaterThanOrEqualTo(2),
        reason:
            'Device cold-cache validation requires at least two shareable contacts on the test device.',
      );

      final matchedContacts = allContacts
          .take(
            (allContacts.length - 1).clamp(1, 40),
          )
          .toList(growable: false);

      final primingBackend = _ColdCacheInvitesBackend(
        matchPayloadsByHash: {
          for (final entry in matchedContacts.asMap().entries)
            InviteContactImportHashes.contactHashes(
              entry.value,
              regionCode: 'BR',
            ).first: _matchPayload(
              contactHash: InviteContactImportHashes.contactHashes(
                entry.value,
                regionCode: 'BR',
              ).first,
              index: entry.key,
              displayName: 'Matched ${entry.key}',
            ),
        },
      );
      final primingInvitesRepository = InvitesRepository(
        backend: primingBackend,
        contactImportCache: InviteContactImportCache(),
        now: () => now,
        currentUserIdProvider: () async => viewerId,
        tenantCacheScopeProvider: () async => tenantScope,
      );
      final primingInviteContacts =
          InviteContacts(regionCodeValue: _inviteContactRegionCode('BR'));
      for (final contact in allContacts) {
        primingInviteContacts.add(contact);
      }
      await primingInvitesRepository.importContacts(primingInviteContacts);

      final refreshGate = Completer<void>();
      final coldBackend = _ColdCacheInvitesBackend(
        matchPayloadsByHash: primingBackend.matchPayloadsByHash,
        fetchInviteableRecipientsGate: refreshGate,
      );
      final coldContactsProbeRepository = ContactsRepository(
        localCache: ContactsLocalCache(),
        permissionRequester: () async => true,
        deviceContactsLoader: () async => const <ContactModel>[],
      );
      await coldContactsProbeRepository.loadCachedContacts();
      final coldCachedContacts =
          coldContactsProbeRepository.contactsStreamValue.value;
      expect(
        coldCachedContacts,
        isNotNull,
        reason:
            'Cold device validation must read persisted device contacts before the screen opens.',
      );
      expect(
        coldCachedContacts,
        isNotEmpty,
        reason:
            'Cold device validation requires at least one persisted device contact before the screen opens.',
      );
      final coldShareableContacts = (coldCachedContacts ?? const <ContactModel>[])
          .where((contact) => contact.phones.isNotEmpty || contact.emails.isNotEmpty)
          .toList(growable: false);
      expect(
        coldShareableContacts.length,
        allContacts.length,
        reason:
            'Cold device validation must preserve the same shareable contacts after local cache rehydration.',
      );
      final coldContactsRepository = ContactsRepository(
        localCache: ContactsLocalCache(),
        permissionRequester: () async => true,
        deviceContactsLoader: () async => const <ContactModel>[],
      );
      final coldCacheProbeRepository = InvitesRepository(
        backend: coldBackend,
        contactImportCache: InviteContactImportCache(),
        now: () => now.add(const Duration(minutes: 5)),
        currentUserIdProvider: () async => viewerId,
        persistedTenantCacheScopeProvider: () async => tenantScope,
      );
      final cachedMatches = await coldCacheProbeRepository
          .hydrateImportedContactMatchesFromCache(primingInviteContacts);
      expect(
        cachedMatches,
        isNotNull,
        reason: 'Cold device validation must read imported matches from cache.',
      );
      expect(
        cachedMatches,
        isNotEmpty,
        reason:
            'Cold device validation requires at least one cached imported match before the UI opens.',
      );
      final coldCachedInviteContacts =
          InviteContacts(regionCodeValue: _inviteContactRegionCode('BR'));
      for (final contact in coldShareableContacts) {
        coldCachedInviteContacts.add(contact);
      }
      final cachedMatchesFromColdContacts = await coldCacheProbeRepository
          .hydrateImportedContactMatchesFromCache(coldCachedInviteContacts);
      expect(
        cachedMatchesFromColdContacts,
        isNotNull,
        reason:
            'Cold device validation must read imported matches using the rehydrated local contacts.',
      );
      expect(
        cachedMatchesFromColdContacts,
        isNotEmpty,
        reason:
            'Cold device validation requires imported-match cache signatures to stay stable after local contact rehydration.',
      );
      final coldInvitesRepository = InvitesRepository(
        backend: coldBackend,
        contactImportCache: InviteContactImportCache(),
        now: () => now.add(const Duration(minutes: 5)),
        currentUserIdProvider: () async => viewerId,
        persistedTenantCacheScopeProvider: () async => tenantScope,
      );
      final controller = InviteShareScreenController(
        invitesRepository: coldInvitesRepository,
        contactsRepository: coldContactsRepository,
        appData: _buildAppData(),
        isWebRuntime: false,
        contactRegionCode: 'BR',
      );
      GetIt.I.registerSingleton<InviteShareScreenController>(controller);
      addTearDown(() async {
        if (!refreshGate.isCompleted) {
          refreshGate.complete();
        }
        await controller.onDispose();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: InviteShareScreen(invite: _buildInvite()),
        ),
      );
      await tester.pump();

      final appPaneHydrated = await _waitUntilCondition(
        tester,
        () => (controller.friendsSuggestionsStreamValue.value?.isNotEmpty ??
            false),
        forbiddenFinders: <Finder>[
          find.text('Nenhum contato convidável para este filtro.'),
        ],
      );
      expect(
        appPaneHydrated,
        isTrue,
        reason: [
          'cold app pane did not hydrate from cache',
          'cachedContacts=${coldContactsRepository.contactsStreamValue.value?.length ?? 0}',
          'shareableContacts=${(coldContactsRepository.contactsStreamValue.value ?? const <ContactModel>[]).where((contact) => contact.phones.isNotEmpty || contact.emails.isNotEmpty).length}',
          'region=${controller.debugContactRegionCodeValue ?? 'null'}',
          'importedMatches=${coldInvitesRepository.importedContactMatchesStreamValue.value?.length ?? 0}',
          'inviteables=${coldInvitesRepository.inviteableRecipientsStreamValue.value?.length ?? 0}',
          'friends=${controller.friendsSuggestionsStreamValue.value?.length ?? 0}',
        ].join(' | '),
      );
      await _scrollUntilVisible(
        tester,
        _nonPlaceholderAppCardFinder(),
      );

      await tester.tap(find.text('Agenda'));
      await tester.pump();

      await _pumpUntilCondition(
        tester,
        () =>
            (controller.externalContactShareTargetsStreamValue.value?.isNotEmpty ??
                false),
        forbiddenFinders: <Finder>[
          find.text('Nenhum contato do telefone disponível.'),
        ],
      );
      await _scrollUntilVisible(
        tester,
        find.byType(InviteExternalContactCard),
      );

      refreshGate.complete();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tenant Test'));
      await tester.pumpAndSettle();
      expect(_nonPlaceholderAppCardFinder(), findsWidgets);
      await tester.tap(find.text('Agenda'));
      await tester.pumpAndSettle();
      expect(find.byType(InviteExternalContactCard), findsWidgets);
    },
  );
}

Finder _nonPlaceholderAppCardFinder() {
  return find.byWidgetPredicate(
    (widget) => widget is InviteShareFriendCard && !widget.isPlaceholder,
    description: 'non-placeholder InviteShareFriendCard',
  );
}

Future<bool> _waitUntilCondition(
  WidgetTester tester,
  bool Function() condition, {
  required List<Finder> forbiddenFinders,
  Duration step = const Duration(milliseconds: 50),
  int maxTicks = 40,
}) async {
  for (var tick = 0; tick < maxTicks; tick += 1) {
    for (final forbiddenFinder in forbiddenFinders) {
      expect(forbiddenFinder, findsNothing);
    }
    if (condition()) {
      return true;
    }
    await tester.pump(step);
  }
  return condition();
}

Future<void> _pumpUntilCondition(
  WidgetTester tester,
  bool Function() condition, {
  required List<Finder> forbiddenFinders,
  Duration step = const Duration(milliseconds: 50),
  int maxTicks = 40,
}) async {
  expect(
    await _waitUntilCondition(
      tester,
      condition,
      forbiddenFinders: forbiddenFinders,
      step: step,
      maxTicks: maxTicks,
    ),
    isTrue,
  );
}

Future<void> _scrollUntilVisible(
  WidgetTester tester,
  Finder finder, {
  double delta = 300,
  int maxScrolls = 8,
}) async {
  if (finder.evaluate().isNotEmpty) {
    return;
  }

  final scrollable = find.byType(Scrollable).first;
  for (var attempt = 0; attempt < maxScrolls; attempt += 1) {
    await tester.drag(scrollable, Offset(0, -delta));
    await tester.pumpAndSettle();
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  expect(finder, findsWidgets);
}

class _ColdCacheInvitesBackend implements InvitesBackendContract {
  _ColdCacheInvitesBackend({
    required this.matchPayloadsByHash,
    this.fetchInviteableRecipientsGate,
  });

  final Map<String, Map<String, dynamic>> matchPayloadsByHash;
  final Completer<void>? fetchInviteableRecipientsGate;

  @override
  Future<Map<String, dynamic>> fetchInviteableContacts() async {
    final gate = fetchInviteableRecipientsGate;
    if (gate != null && !gate.isCompleted) {
      await gate.future;
    }
    return const <String, dynamic>{'items': <Map<String, dynamic>>[]};
  }

  @override
  Future<Map<String, dynamic>> importContacts(
    InviteContactImportRequest request,
  ) async {
    final matches = <Map<String, dynamic>>[];
    for (final item in request.contacts) {
      final match = matchPayloadsByHash[item.hash];
      if (match != null) {
        matches.add(match);
      }
    }
    return <String, dynamic>{'matches': matches};
  }

  @override
  Future<Map<String, dynamic>> createShareCode(
    InviteShareCodeCreateRequest request,
  ) async {
    return <String, dynamic>{
      'code': 'cold-cache-code',
      'target_ref': <String, dynamic>{
        'event_id': request.targetRef.eventId,
        'occurrence_id': request.targetRef.occurrenceId,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> fetchInvites({
    required int page,
    required int pageSize,
  }) async =>
      const <String, dynamic>{'invites': <Map<String, dynamic>>[]};

  @override
  Stream<InviteRealtimeDeltaDto> watchInvitesStream({
    String? lastEventId,
  }) =>
      const Stream<InviteRealtimeDeltaDto>.empty();

  @override
  Future<Map<String, dynamic>> fetchSettings() async =>
      const <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> acceptInvite(String inviteId) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> declineInvite(String inviteId) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> sendInvites(InviteSendRequest request) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> fetchShareCodePreview(String code) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> acceptShareCode(String code) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> materializeShareCode(String code) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> fetchContactGroups() async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> createContactGroup({
    required String name,
    required List<String> recipientAccountProfileIds,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> updateContactGroup({
    required String groupId,
    String? name,
    List<String>? recipientAccountProfileIds,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> deleteContactGroup(String groupId) async =>
      throw UnimplementedError();
}

Map<String, dynamic> _matchPayload({
  required String contactHash,
  required int index,
  required String displayName,
}) {
  return <String, dynamic>{
    'contact_hash': contactHash,
    'type': 'phone',
    'user_id': 'user-$index',
    'receiver_account_profile_id': 'profile-$index',
    'display_name': displayName,
    'avatar_url': null,
    'profile_exposure_level': 'capped_profile',
    'inviteable_reasons': const <String>['contact_match'],
    'is_inviteable': true,
  };
}

InviteContactRegionCodeValue _inviteContactRegionCode(String value) {
  final regionCodeValue = InviteContactRegionCodeValue();
  regionCodeValue.parse(value);
  return regionCodeValue;
}

InviteModel _buildInvite() {
  return buildInviteModelFromPrimitives(
    id: 'invite-1',
    eventId: 'event-1',
    eventName: 'Evento Teste',
    eventDateTime: DateTime(2026, 3, 13, 20),
    eventImageUrl: 'https://example.com/event.jpg',
    location: 'Guarapari',
    hostName: 'Host',
    occurrenceId: 'occurrence-1',
    message: 'Bora?',
    tags: const <String>['music'],
    inviterName: 'Amigo',
  );
}

AppData _buildAppData() {
  return buildAppDataFromInitialization(
    remoteData: const <String, dynamic>{
      'name': 'Tenant Test',
      'type': 'tenant',
      'main_domain': 'https://tenant.test',
      'profile_types': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'personal',
          'label': 'Personal',
          'allowed_taxonomies': <String>[],
          'capabilities': <String, dynamic>{
            'is_favoritable': true,
            'is_poi_enabled': false,
          },
        },
      ],
      'domains': <String>['https://tenant.test'],
      'app_domains': <String>[],
      'theme_data_settings': <String, dynamic>{
        'brightness_default': 'light',
        'primary_seed_color': '#FFFFFF',
        'secondary_seed_color': '#000000',
      },
      'main_color': '#FFFFFF',
      'tenant_id': 'tenant-1',
      'telemetry': <String, dynamic>{'trackers': <dynamic>[]},
      'telemetry_context': <String, dynamic>{
        'location_freshness_minutes': 5,
      },
      'firebase': null,
      'push': null,
    },
    localInfo: <String, dynamic>{
      'platformType': PlatformTypeValue()..parse('mobile'),
      'hostname': 'tenant.test',
      'href': 'https://tenant.test',
      'port': null,
      'device': 'invite-share-cold-cache-device-test',
    },
  );
}
