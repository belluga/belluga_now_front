import 'dart:convert';
import 'dart:typed_data';

import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_events_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_account_profile_candidate_type.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_event_temporal_bucket.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_term.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_value_parsers.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_events_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_taxonomy_terms.dart';

void main() {
  TenantAdminEventsRepoString _repoText(String value) {
    return TenantAdminEventsRepoString.fromRaw(
      value,
      defaultValue: value,
    );
  }

  TenantAdminEventsRepoInt _repoInt(int value) {
    return TenantAdminEventsRepoInt.fromRaw(
      value,
      defaultValue: value,
    );
  }

  TenantAdminEventsRepoBool _repoBool(bool value) {
    return TenantAdminEventsRepoBool.fromRaw(
      value,
      defaultValue: value,
    );
  }

  Future<void> registerAuth({
    required String landlordToken,
    required String accountToken,
  }) async {
    if (GetIt.I.isRegistered<LandlordAuthRepositoryContract>()) {
      GetIt.I.unregister<LandlordAuthRepositoryContract>();
    }
    if (GetIt.I.isRegistered<AuthRepositoryContract>()) {
      GetIt.I.unregister<AuthRepositoryContract>();
    }

    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(
      _StubAuthRepo(tokenValue: landlordToken),
    );
    GetIt.I.registerSingleton<AuthRepositoryContract>(
      _StubAccountAuthRepo(tokenValue: accountToken),
    );
  }

  setUp(() async {
    await GetIt.I.reset();
    await registerAuth(
      landlordToken: 'test-token',
      accountToken: 'account-token',
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('createEvent persists taxonomy terms in payload', () async {
    final adapter = _EventsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final created = await repository.createEvent(
      draft: _buildDraft(
        taxonomyTerms: (() {
          final terms = TenantAdminTaxonomyTerms();
          terms.add(
            tenantAdminTaxonomyTermFromRaw(type: 'music_genre', value: 'rock'),
          );
          terms.add(
            tenantAdminTaxonomyTermFromRaw(
              type: 'audience',
              value: 'families',
            ),
          );
          return terms;
        })(),
      ),
    );

    expect(adapter.requests, isNotEmpty);
    final request = adapter.requests.last;
    expect(request.method, 'POST');
    expect(request.path, endsWith('/admin/api/v1/events'));
    expect(request.data, isA<Map<String, dynamic>>());
    final payload = request.data as Map<String, dynamic>;
    expect(payload['taxonomy_terms'], isA<List<dynamic>>());
    final terms = payload['taxonomy_terms'] as List<dynamic>;
    expect(terms, hasLength(2));
    expect(
      terms,
      containsAll([
        {'type': 'music_genre', 'value': 'rock'},
        {'type': 'audience', 'value': 'families'},
      ]),
    );
    expect(created.taxonomyTerms.map((term) => term.type),
        contains('music_genre'));
  });

  test(
      'createEvent omits geo payload for online mode even when coordinates exist',
      () async {
    final adapter = _EventsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.createEvent(
      draft: _buildDraft(
        location: TenantAdminEventLocation(
          modeValue: tenantAdminRequiredText('online'),
          latitudeValue: tenantAdminOptionalDouble(-20.611121),
          longitudeValue: tenantAdminOptionalDouble(-40.498617),
          online: TenantAdminEventOnlineLocation(
            urlValue: tenantAdminRequiredText('https://example.com/live'),
          ),
        ),
      ),
    );

    expect(adapter.requests, isNotEmpty);
    final request = adapter.requests.last;
    expect(request.method, 'POST');
    expect(request.path, endsWith('/admin/api/v1/events'));
    final payload = request.data as Map<String, dynamic>;
    final location = payload['location'] as Map<String, dynamic>;
    expect(location['mode'], 'online');
    expect(location.containsKey('geo'), isFalse);
    expect(location['online'], {'url': 'https://example.com/live'});
  });

  test('createEvent keeps account_profile place_ref contract for physical mode',
      () async {
    final adapter = _EventsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.createEvent(
      draft: _buildDraft(
        location: TenantAdminEventLocation(
          modeValue: tenantAdminRequiredText('physical'),
          latitudeValue: tenantAdminOptionalDouble(-20.611121),
          longitudeValue: tenantAdminOptionalDouble(-40.498617),
        ),
        placeRef: TenantAdminEventPlaceRef(
          typeValue: tenantAdminRequiredText('account_profile'),
          idValue: tenantAdminRequiredText('profile-1'),
        ),
      ),
    );

    expect(adapter.requests, isNotEmpty);
    final request = adapter.requests.last;
    expect(request.method, 'POST');
    expect(request.path, endsWith('/admin/api/v1/events'));
    final payload = request.data as Map<String, dynamic>;
    expect(payload['place_ref'], isA<Map<String, dynamic>>());
    final placeRef = payload['place_ref'] as Map<String, dynamic>;
    expect(placeRef['type'], 'account_profile');
    expect(placeRef['id'], 'profile-1');
  });

  test('createOwnEvent uses account-scoped endpoint', () async {
    final adapter = _EventsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.createOwnEvent(
      accountSlug: _repoText('my-account'),
      draft: _buildDraft(),
    );

    expect(adapter.requests, isNotEmpty);
    final request = adapter.requests.last;
    expect(request.method, 'POST');
    expect(request.path, endsWith('/api/v1/accounts/my-account/events'));
    expect(request.headers['Authorization'], 'Bearer account-token');
  });

  test('createEvent uses multipart payload when cover upload is provided',
      () async {
    final adapter = _EventsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.createEvent(
      draft: _buildDraft(
        coverUpload: tenantAdminMediaUploadFromRaw(
          bytes: Uint8List.fromList([1, 2, 3, 4]),
          fileName: 'event-cover.png',
          mimeType: 'image/png',
        ),
      ),
    );

    final request = adapter.requests.last;
    expect(request.method, 'POST');
    expect(request.path, endsWith('/admin/api/v1/events'));
    expect(request.data, isA<FormData>());
    final formData = request.data as FormData;
    expect(formData.files.map((entry) => entry.key), contains('cover'));
  });

  test('updateEvent sends remove_cover as multipart patch override', () async {
    final adapter = _EventsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.updateEvent(
      eventId: _repoText('evt-1'),
      draft: _buildDraft(removeCover: true),
    );

    final request = adapter.requests.last;
    expect(request.method, 'POST');
    expect(request.path, endsWith('/admin/api/v1/events/evt-1'));
    expect(request.data, isA<FormData>());
    final formData = request.data as FormData;
    expect(formData.fields, contains(const MapEntry('remove_cover', '1')));
    expect(formData.fields, contains(const MapEntry('_method', 'PATCH')));
  });

  test('fetchEventsPage propagates 404 as repository error', () async {
    final adapter = _NotFoundEventsAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await expectLater(
      repository.fetchEventsPage(
        page: _repoInt(1),
        pageSize: _repoInt(20),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('status=404'),
        ),
      ),
    );
  });

  test('fetchEventsPage serializes archived filter as integer boolean',
      () async {
    final adapter = _EventsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.fetchEventsPage(
      page: _repoInt(1),
      pageSize: _repoInt(20),
      archived: _repoBool(true),
    );

    final request = adapter.requests.lastWhere(
      (request) =>
          request.method == 'GET' &&
          request.path.endsWith('/admin/api/v1/events'),
    );
    expect(request.queryParameters['archived'], 1);
  });

  test('fetchEventsPage serializes specific date as date query parameter',
      () async {
    final adapter = _EventsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.fetchEventsPage(
      page: _repoInt(1),
      pageSize: _repoInt(20),
      specificDate: _repoText('2026-04-10'),
    );

    final request = adapter.requests.lastWhere(
      (request) =>
          request.method == 'GET' &&
          request.path.endsWith('/admin/api/v1/events'),
    );
    expect(request.queryParameters['date'], '2026-04-10');
  });

  test('fetchEventsPage never serializes retired direct search parameter',
      () async {
    final adapter = _EventsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.fetchEventsPage(
      page: _repoInt(1),
      pageSize: _repoInt(20),
      search: _repoText('legacy search'),
    );

    final request = adapter.requests.lastWhere(
      (request) =>
          request.method == 'GET' &&
          request.path.endsWith('/admin/api/v1/events'),
    );
    expect(request.queryParameters.containsKey('search'), isFalse);
  });

  test('fetchEventsPage serializes temporal filter as csv query parameter',
      () async {
    final adapter = _EventsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.fetchEventsPage(
      page: _repoInt(1),
      pageSize: _repoInt(20),
      temporalBuckets: const <TenantAdminEventTemporalBucket>{
        TenantAdminEventTemporalBucket.now,
        TenantAdminEventTemporalBucket.future,
      },
    );

    final request = adapter.requests.lastWhere(
      (request) =>
          request.method == 'GET' &&
          request.path.endsWith('/admin/api/v1/events'),
    );
    expect(request.queryParameters['temporal'], 'now,future');
  });

  test(
      'fetchEventsPage serializes venue and related account profile filters as dedicated query parameters',
      () async {
    final adapter = _EventsRoutingAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.fetchEventsPage(
      page: _repoInt(1),
      pageSize: _repoInt(20),
      venueProfileId: _repoText('venue-42'),
      relatedAccountProfileId: _repoText('profile-77'),
    );

    final request = adapter.requests.lastWhere(
      (request) =>
          request.method == 'GET' &&
          request.path.endsWith('/admin/api/v1/events'),
    );
    expect(request.queryParameters['venue_profile_id'], 'venue-42');
    expect(
      request.queryParameters['related_account_profile_id'],
      'profile-77',
    );
  });

  test(
      'fetchEventsPage decodes summarized related account profiles without requiring full account profile payload',
      () async {
    final adapter = _EventsListWithSummarizedRelatedProfilesAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final result = await repository.fetchEventsPage(
      page: _repoInt(1),
      pageSize: _repoInt(20),
    );

    expect(result.items, hasLength(1));
    expect(result.items.first.title, 'Summarized Artist Event');
    expect(result.items.first.relatedAccountProfiles, hasLength(1));
    expect(
      result.items.first.relatedAccountProfiles.first.id,
      'artist-summary-1',
    );
    expect(
      result.items.first.relatedAccountProfiles.first.displayName,
      'DJ Summary',
    );
    expect(
      result.items.first.relatedAccountProfiles.first.profileType,
      'artist',
    );
    expect(
      result.items.first.relatedAccountProfiles.first.accountId,
      'artist-summary-1',
    );
  });

  test('fetchEventsPage wraps decoder failures with readable repository error',
      () async {
    final adapter = _MalformedEventsPayloadAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await expectLater(
      repository.fetchEventsPage(
        page: _repoInt(1),
        pageSize: _repoInt(20),
        archived: _repoBool(true),
      ),
      throwsA(
        isA<FormatException>()
            .having(
              (error) => error.message,
              'message',
              contains('Failed to load events page [decode]'),
            )
            .having(
              (error) => error.message,
              'message',
              contains('Invalid scalar text value'),
            )
            .having(
              (error) => error.message,
              'message',
              contains('/admin/api/v1/events'),
            ),
      ),
    );
  });

  test('fetchEventTypes prefers landlord token and maps payload', () async {
    final adapter = _EventTypesAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final eventTypes = await repository.fetchEventTypes();

    expect(eventTypes, hasLength(2));
    expect(eventTypes[0].id, '507f1f77bcf86cd799439011');
    expect(eventTypes[0].name, 'Show');
    expect(eventTypes[0].slug, 'show');
    expect(eventTypes[1].id, '507f1f77bcf86cd799439012');
    expect(eventTypes[1].name, 'Workshop');
    expect(eventTypes[1].slug, 'workshop');

    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.first;
    expect(request.method, 'GET');
    expect(request.path, endsWith('/admin/api/v1/event_types'));
    expect(request.headers['Authorization'], 'Bearer test-token');
  });

  test('fetchEventTypes falls back to account token when landlord token empty',
      () async {
    await registerAuth(
      landlordToken: '',
      accountToken: 'account-token',
    );

    final adapter = _EventTypesAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final eventTypes = await repository.fetchEventTypes();

    expect(eventTypes, hasLength(2));
    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.first;
    expect(request.method, 'GET');
    expect(request.path, endsWith('/admin/api/v1/event_types'));
    expect(request.headers['Authorization'], 'Bearer account-token');
  });

  test('fetchEventTypes throws when both landlord and account token are empty',
      () async {
    await registerAuth(
      landlordToken: '',
      accountToken: '',
    );

    final adapter = _EventTypesAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await expectLater(
      () => repository.fetchEventTypes(),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Failed to resolve auth token for event types request.'),
        ),
      ),
    );
  });

  test('fetchEventAccountProfileCandidatesPage uses dedicated endpoint',
      () async {
    final adapter = _AccountProfileCandidatesAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final candidates = await repository.fetchEventAccountProfileCandidatesPage(
      candidateType: TenantAdminEventAccountProfileCandidateType.physicalHost,
      page: _repoInt(1),
      pageSize: _repoInt(20),
      search: _repoText('main'),
    );

    expect(candidates.items, hasLength(1));
    expect(candidates.items.first.id, 'venue-1');
    expect(candidates.items.first.profileType, 'venue');
    expect(candidates.hasMore, isFalse);

    final candidateRequests = adapter.requests
        .where((request) => request.path
            .endsWith('/admin/api/v1/events/account_profile_candidates'))
        .toList(growable: false);

    expect(candidateRequests, hasLength(1));
    expect(candidateRequests.first.queryParameters['type'], 'physical_host');
    expect(candidateRequests.first.queryParameters['page'], 1);
    expect(candidateRequests.first.queryParameters['page_size'], 20);
    expect(candidateRequests.first.queryParameters['search'], 'main');
    expect(
        candidateRequests.first.headers['Authorization'], 'Bearer test-token');
  });

  test(
      'fetchEventAccountProfileCandidatesPage derives hasMore from backend pagination metadata',
      () async {
    final adapter = _AccountProfileCandidatesAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final candidates = await repository.fetchEventAccountProfileCandidatesPage(
      candidateType:
          TenantAdminEventAccountProfileCandidateType.relatedAccountProfile,
      page: _repoInt(2),
      pageSize: _repoInt(20),
      search: _repoText('paged'),
    );

    expect(candidates.items, hasLength(20));
    expect(candidates.items.first.id, 'artist-page-21');
    expect(candidates.items.first.displayName, 'Paged Artist 021');
    expect(candidates.hasMore, isTrue);

    final candidateRequests = adapter.requests
        .where((request) => request.path
            .endsWith('/admin/api/v1/events/account_profile_candidates'))
        .toList(growable: false);

    expect(candidateRequests, hasLength(1));
    expect(candidateRequests.first.queryParameters['page'], 2);
    expect(candidateRequests.first.queryParameters['page_size'], 20);
    expect(candidateRequests.first.queryParameters['search'], 'paged');
  });

  test(
      'fetchEventAccountProfileCandidatesPage uses account-scoped endpoint for own-create flow',
      () async {
    final adapter = _AccountProfileCandidatesAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final candidates = await repository.fetchEventAccountProfileCandidatesPage(
      candidateType: TenantAdminEventAccountProfileCandidateType.physicalHost,
      page: _repoInt(2),
      pageSize: _repoInt(10),
      search: _repoText('main'),
      accountSlug: _repoText('my-account'),
    );

    expect(candidates.items, hasLength(1));
    expect(candidates.items.first.id, 'venue-1');
    expect(candidates.items.first.profileType, 'venue');

    final candidateRequests = adapter.requests
        .where((request) => request.path.endsWith(
            '/api/v1/accounts/my-account/events/account_profile_candidates'))
        .toList(growable: false);

    expect(candidateRequests, hasLength(1));
    expect(candidateRequests.first.queryParameters['type'], 'physical_host');
    expect(candidateRequests.first.queryParameters['page'], 2);
    expect(candidateRequests.first.queryParameters['page_size'], 10);
    expect(candidateRequests.first.queryParameters['search'], 'main');
    expect(candidateRequests.first.headers['Authorization'],
        'Bearer account-token');
  });

  test(
      'fetchEventAccountProfileCandidatesPage decodes related account profile candidate pages',
      () async {
    final adapter = _AccountProfileCandidatesAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    final candidates = await repository.fetchEventAccountProfileCandidatesPage(
      candidateType:
          TenantAdminEventAccountProfileCandidateType.relatedAccountProfile,
      page: _repoInt(1),
      pageSize: _repoInt(20),
      search: _repoText('dj'),
    );

    expect(candidates.items, hasLength(1));
    expect(candidates.items.first.id, 'artist-1');
    expect(candidates.items.first.profileType, 'artist');
  });

  test(
      'fetchEventAccountProfileCandidatesPage throws when endpoint is unauthorized',
      () async {
    final adapter = _UnauthorizedAdminAccountProfileCandidatesAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await expectLater(
      () => repository.fetchEventAccountProfileCandidatesPage(
        candidateType:
            TenantAdminEventAccountProfileCandidateType.relatedAccountProfile,
        page: _repoInt(1),
        pageSize: _repoInt(20),
        search: _repoText('main'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('Failed to load event account profile candidates'),
        ),
      ),
    );

    final candidateRequests = adapter.requests
        .where((request) => request.path
            .endsWith('/admin/api/v1/events/account_profile_candidates'))
        .toList(growable: false);
    expect(candidateRequests, hasLength(1));
  });

  test(
      'fetchEventAccountProfileCandidatesPage throws when endpoint is not found',
      () async {
    final adapter = _NotFoundAdminAccountProfileCandidatesAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await expectLater(
      () => repository.fetchEventAccountProfileCandidatesPage(
        candidateType:
            TenantAdminEventAccountProfileCandidateType.relatedAccountProfile,
        page: _repoInt(1),
        pageSize: _repoInt(20),
        search: _repoText('main'),
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          allOf(
            contains('Failed to load event account profile candidates'),
            contains('status=404'),
          ),
        ),
      ),
    );

    final candidateRequests = adapter.requests
        .where((request) => request.path
            .endsWith('/admin/api/v1/events/account_profile_candidates'))
        .toList(growable: false);
    expect(candidateRequests, hasLength(1));
  });

  test('updateEventType sends null description when value is cleared',
      () async {
    final adapter = _EventTypeMutationsAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.updateEventType(
      eventTypeId: _repoText('507f1f77bcf86cd799439011'),
      name: _repoText('Show'),
      slug: _repoText('show'),
      description: null,
    );

    final request = adapter.requests.singleWhere(
      (candidate) =>
          candidate.method == 'PATCH' &&
          candidate.path
              .endsWith('/admin/api/v1/event_types/507f1f77bcf86cd799439011'),
    );

    expect(request.data, isA<Map<String, dynamic>>());
    final payload = request.data as Map<String, dynamic>;
    expect(payload['name'], 'Show');
    expect(payload['slug'], 'show');
    expect(payload.containsKey('description'), isTrue);
    expect(payload['description'], isNull);
  });

  test('createEventType omits description when value is blank', () async {
    final adapter = _EventTypeMutationsAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.createEventType(
      name: _repoText('Show'),
      slug: _repoText('show'),
      description: _repoText('   '),
    );

    final request = adapter.requests.singleWhere(
      (candidate) =>
          candidate.method == 'POST' &&
          candidate.path.endsWith('/admin/api/v1/event_types'),
    );

    expect(request.data, isA<Map<String, dynamic>>());
    final payload = request.data as Map<String, dynamic>;
    expect(payload['name'], 'Show');
    expect(payload['slug'], 'show');
    expect(payload.containsKey('description'), isFalse);
  });

  test('createEventTypeWithVisual sends canonical and legacy visual payloads',
      () async {
    final adapter = _EventTypeMutationsAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.createEventTypeWithVisual(
      name: _repoText('Festival'),
      slug: _repoText('festival'),
      description: _repoText('Tipo com imagem'),
      visual: TenantAdminPoiVisual.image(
        imageSource: TenantAdminPoiVisualImageSource.cover,
      ),
    );

    final request = adapter.requests.singleWhere(
      (candidate) =>
          candidate.method == 'POST' &&
          candidate.path.endsWith('/admin/api/v1/event_types'),
    );

    expect(request.data, isA<Map<String, dynamic>>());
    final payload = request.data as Map<String, dynamic>;
    expect(payload['visual'], <String, dynamic>{
      'mode': 'image',
      'image_source': 'cover',
    });
    expect(payload['poi_visual'], <String, dynamic>{
      'mode': 'image',
      'image_source': 'cover',
    });
  });

  test('updateEventTypeWithVisual uses multipart when type_asset upload exists',
      () async {
    final adapter = _EventTypeMutationsAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final scope = _MutableTenantScope('https://tenant-a.test/admin/api');
    final repository = TenantAdminEventsRepository(
      dio: dio,
      tenantScope: scope,
    );

    await repository.updateEventTypeWithVisual(
      eventTypeId: _repoText('507f1f77bcf86cd799439011'),
      visual: TenantAdminPoiVisual.image(
        imageSource: TenantAdminPoiVisualImageSource.typeAsset,
      ),
      typeAssetUpload: tenantAdminMediaUploadFromRaw(
        bytes: Uint8List.fromList([4, 5, 6]),
        fileName: 'festival-type.png',
        mimeType: 'image/png',
      ),
    );

    final request = adapter.requests.singleWhere(
      (candidate) =>
          candidate.method == 'POST' &&
          candidate.path
              .endsWith('/admin/api/v1/event_types/507f1f77bcf86cd799439011'),
    );

    expect(request.data, isA<FormData>());
    final formData = request.data as FormData;
    expect(formData.fields, contains(const MapEntry('_method', 'PATCH')));
    expect(
      formData.fields.any(
        (entry) =>
            entry.key == 'visual[image_source]' && entry.value == 'type_asset',
      ),
      isTrue,
    );
    expect(
      formData.fields.any(
        (entry) =>
            entry.key == 'poi_visual[image_source]' &&
            entry.value == 'type_asset',
      ),
      isTrue,
    );
    expect(formData.files.any((entry) => entry.key == 'type_asset'), isTrue);
  });
}

TenantAdminEventDraft _buildDraft({
  TenantAdminTaxonomyTerms taxonomyTerms =
      const TenantAdminTaxonomyTerms.empty(),
  TenantAdminEventLocation? location,
  TenantAdminEventPlaceRef? placeRef,
  TenantAdminMediaUpload? coverUpload,
  bool removeCover = false,
}) {
  return TenantAdminEventDraft(
    titleValue: tenantAdminRequiredText('My event'),
    contentValue: tenantAdminOptionalText('Content'),
    type: TenantAdminEventType(
      nameValue: tenantAdminRequiredText('Show'),
      slugValue: tenantAdminRequiredText('show'),
    ),
    occurrences: [
      TenantAdminEventOccurrence(
        dateTimeStartValue: tenantAdminDateTime(DateTime(2026, 3, 5, 20)),
      ),
    ],
    publication: TenantAdminEventPublication(
      statusValue: tenantAdminRequiredText('draft'),
    ),
    location: location,
    placeRef: placeRef,
    coverUpload: coverUpload,
    removeCoverValue: tenantAdminFlag(removeCover),
    taxonomyTerms: taxonomyTerms,
  );
}

class _StubAuthRepo implements LandlordAuthRepositoryContract {
  _StubAuthRepo({required this.tokenValue});

  final String tokenValue;

  @override
  bool get hasValidSession => tokenValue.trim().isNotEmpty;

  @override
  String get token => tokenValue;

  @override
  Future<void> init() async {}

  @override
  Future<void> loginWithEmailPassword(
    LandlordAuthRepositoryContractPrimString email,
    LandlordAuthRepositoryContractPrimString password,
  ) async {}

  @override
  Future<void> logout() async {}
}

class _StubAccountAuthRepo implements AuthRepositoryContract<UserContract> {
  _StubAccountAuthRepo({required this.tokenValue});

  final String tokenValue;

  @override
  Object get backend => Object();

  @override
  final userStreamValue = StreamValue<UserContract?>();

  @override
  UserContract get user => throw UnimplementedError();

  @override
  String get userToken => tokenValue;

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  Future<String> getDeviceId() async => 'device-id';

  @override
  Future<String?> getUserId() async => 'user-1';

  @override
  bool get isUserLoggedIn => true;

  @override
  bool get isAuthorized => true;

  @override
  Future<void> init() async {}

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> loginWithEmailPassword(AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString password) async {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
      AuthRepositoryContractParamString email,
      AuthRepositoryContractParamString codigoEnviado) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(
      AuthRepositoryContractParamString email) async {}

  @override
  Future<void> updateUser(UserCustomData data) async {}
}

class _MutableTenantScope implements TenantAdminTenantScopeContract {
  _MutableTenantScope(String initialBaseUrl) {
    _selectedTenantDomainStreamValue.addValue(initialBaseUrl);
  }

  final StreamValue<String?> _selectedTenantDomainStreamValue =
      StreamValue<String?>(defaultValue: null);

  @override
  String? get selectedTenantDomain => _selectedTenantDomainStreamValue.value;

  @override
  String get selectedTenantAdminBaseUrl => selectedTenantDomain ?? '';

  @override
  StreamValue<String?> get selectedTenantDomainStreamValue =>
      _selectedTenantDomainStreamValue;

  @override
  void clearSelectedTenantDomain() {
    _selectedTenantDomainStreamValue.addValue(null);
  }

  @override
  void selectTenantDomain(Object tenantDomain) {
    _selectedTenantDomainStreamValue.addValue((tenantDomain is String
            ? tenantDomain
            : (tenantDomain as dynamic).value as String)
        .trim());
  }
}

class _EventsRoutingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if ((options.path.endsWith('/v1/events') ||
            options.path.contains('/v1/events/')) &&
        (options.method == 'POST' || options.method == 'PATCH')) {
      final payload = options.data is Map<String, dynamic>
          ? options.data as Map<String, dynamic>
          : <String, dynamic>{};
      return _jsonResponse(
        {'data': _eventFromPayload(payload)},
      );
    }

    if (options.path.contains('/api/v1/accounts/') &&
        options.path.endsWith('/events') &&
        options.method == 'POST') {
      final payload = options.data is Map<String, dynamic>
          ? options.data as Map<String, dynamic>
          : <String, dynamic>{};
      return _jsonResponse(
        {'data': _eventFromPayload(payload)},
      );
    }

    if (options.path.endsWith('/v1/events') && options.method == 'GET') {
      return _jsonResponse({
        'data': [],
        'current_page': 1,
        'last_page': 1,
      });
    }

    return _jsonResponse({'data': {}});
  }

  Map<String, dynamic> _eventFromPayload(Map<String, dynamic> payload) {
    return {
      'event_id': 'evt-1',
      'slug': 'my-event',
      'title': payload['title'] ?? 'My event',
      'content': payload['content'] ?? 'Content',
      'type': payload['type'] ??
          {
            'name': 'Show',
            'slug': 'show',
          },
      'date_time_start': '2026-03-05T20:00:00Z',
      'publication': payload['publication'] ?? {'status': 'draft'},
      'taxonomy_terms': payload['taxonomy_terms'] ?? [],
      'occurrences': payload['occurrences'] ??
          [
            {'date_time_start': '2026-03-05T20:00:00Z'}
          ],
    };
  }

  ResponseBody _jsonResponse(Map<String, dynamic> payload) {
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _EventsListWithSummarizedRelatedProfilesAdapter
    implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/admin/api/v1/events') &&
        options.method == 'GET') {
      return ResponseBody.fromString(
        jsonEncode({
          'data': [
            {
              'event_id': 'evt-summary-1',
              'slug': 'summarized-artist-event',
              'title': 'Summarized Artist Event',
              'content': 'Content',
              'type': {
                'name': 'Show',
                'slug': 'show',
              },
              'publication': {
                'status': 'draft',
              },
              'occurrences': [
                {
                  'date_time_start': '2026-03-05T20:00:00Z',
                }
              ],
              'event_parties': [
                {
                  'party_type': 'artist',
                  'party_ref_id': 'artist-summary-1',
                  'permissions': {
                    'can_edit': true,
                  },
                }
              ],
              'linked_account_profiles': [
                {
                  'id': 'artist-summary-1',
                  'account_id': 'artist-summary-1',
                  'display_name': 'DJ Summary',
                  'profile_type': 'artist',
                  'avatar_url': 'https://example.com/dj-summary.jpg',
                  'slug': 'dj-summary',
                }
              ],
            },
          ],
          'current_page': 1,
          'last_page': 1,
          'per_page': 20,
          'total': 1,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'data': {}}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _NotFoundEventsAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/admin/api/v1/events') &&
        options.method == 'GET') {
      return ResponseBody.fromString(
        jsonEncode({'message': 'No events found'}),
        404,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'data': []}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _MalformedEventsPayloadAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/admin/api/v1/events') &&
        options.method == 'GET') {
      return ResponseBody.fromString(
        jsonEncode({
          'data': [
            {
              'event_id': 'evt-bad',
              'slug': 'bad-event',
              'title': {'raw': 'Bad Event'},
              'content': 'Content',
              'type': {
                'name': 'Show',
                'slug': 'show',
              },
              'publication': {
                'status': 'draft',
              },
              'occurrences': [
                {
                  'date_time_start': '2026-03-05T20:00:00Z',
                }
              ],
            },
          ],
          'current_page': 1,
          'last_page': 1,
          'per_page': 20,
          'total': 1,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'data': {}}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _EventTypesAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (options.path.endsWith('/admin/api/v1/event_types') &&
        options.method == 'GET') {
      return ResponseBody.fromString(
        jsonEncode({
          'data': [
            {
              'id': '507f1f77bcf86cd799439011',
              'name': 'Show',
              'slug': 'show',
              'description': 'Tipo de evento: Show',
            },
            {
              'id': '507f1f77bcf86cd799439012',
              'name': 'Workshop',
              'slug': 'workshop',
              'description': 'Tipo de evento: Workshop',
            },
          ],
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'data': {}}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _AccountProfileCandidatesAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    final isAdminCandidatesRequest = options.path
            .endsWith('/admin/api/v1/events/account_profile_candidates') &&
        options.method == 'GET';
    final isAccountCandidatesRequest =
        options.path.endsWith('/events/account_profile_candidates') &&
            options.path.contains('/api/v1/accounts/') &&
            options.method == 'GET';

    if (isAdminCandidatesRequest || isAccountCandidatesRequest) {
      final rawSearch = options.queryParameters['search']?.toString() ?? '';
      final candidateType = options.queryParameters['type']?.toString();
      final search = rawSearch.trim().toLowerCase();
      final requestedPage =
          int.tryParse(options.queryParameters['page']?.toString() ?? '') ?? 1;
      final requestedPageSize = int.tryParse(
              options.queryParameters['page_size']?.toString() ?? '') ??
          20;
      final venueRows = <Map<String, dynamic>>[
        {
          'id': 'venue-1',
          'account_id': 'account-1',
          'profile_type': 'venue',
          'display_name': 'Main Venue',
          'slug': 'main-venue',
        },
      ];
      final relatedAccountProfileRows = <Map<String, dynamic>>[
        {
          'id': 'artist-1',
          'account_id': 'account-2',
          'profile_type': 'artist',
          'display_name': 'DJ Night',
          'slug': 'dj-night',
        },
      ];
      final pagedRelatedAccountProfileRows =
          List<Map<String, dynamic>>.generate(
        45,
        (index) => {
          'id': 'artist-page-${index + 1}',
          'account_id': 'account-${index + 100}',
          'profile_type': 'artist',
          'display_name':
              'Paged Artist ${(index + 1).toString().padLeft(3, '0')}',
          'slug': 'paged-artist-${index + 1}',
        },
        growable: false,
      );

      List<Map<String, dynamic>> rows;
      int currentPage;
      int lastPage;
      int total;

      switch (candidateType) {
        case 'physical_host':
          rows = venueRows
              .where((row) =>
                  search.isEmpty ||
                  (row['display_name'] as String)
                      .toLowerCase()
                      .contains(search))
              .toList(growable: false);
          currentPage = requestedPage;
          lastPage = requestedPage;
          total = rows.length;
          break;
        case 'related_account_profile':
          final sourceRows = search == 'paged'
              ? pagedRelatedAccountProfileRows
              : relatedAccountProfileRows;
          final filteredRows = sourceRows
              .where((row) =>
                  search.isEmpty ||
                  (row['display_name'] as String)
                      .toLowerCase()
                      .contains(search))
              .toList(growable: false);
          final startIndex = (requestedPage - 1) * requestedPageSize;
          rows = startIndex >= filteredRows.length
              ? const <Map<String, dynamic>>[]
              : filteredRows
                  .skip(startIndex)
                  .take(requestedPageSize)
                  .toList(growable: false);
          currentPage = requestedPage;
          lastPage = filteredRows.isEmpty
              ? requestedPage
              : (filteredRows.length / requestedPageSize).ceil();
          total = filteredRows.length;
          break;
        default:
          rows = const <Map<String, dynamic>>[];
          currentPage = requestedPage;
          lastPage = requestedPage;
          total = 0;
          break;
      }

      return ResponseBody.fromString(
        jsonEncode({
          'data': rows,
          'current_page': currentPage,
          'last_page': lastPage,
          'per_page': requestedPageSize,
          'total': total,
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    if (options.path.endsWith('/admin/api/v1/events') &&
        options.method == 'GET') {
      return ResponseBody.fromString(
        jsonEncode({'data': [], 'current_page': 1, 'last_page': 1}),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'data': {}}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _EventTypeMutationsAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (options.path.endsWith('/admin/api/v1/event_types') &&
        options.method == 'POST') {
      return ResponseBody.fromString(
        jsonEncode({
          'data': {
            'id': '507f1f77bcf86cd799439099',
            'name': 'Show',
            'slug': 'show',
            'description': null,
          },
        }),
        201,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    if (options.path.contains('/admin/api/v1/event_types/') &&
        (options.method == 'PATCH' || options.method == 'POST')) {
      return ResponseBody.fromString(
        jsonEncode({
          'data': {
            'id': '507f1f77bcf86cd799439011',
            'name': 'Show',
            'slug': 'show',
            'description': null,
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'data': {}}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _UnauthorizedAdminAccountProfileCandidatesAdapter
    implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (options.path
            .endsWith('/admin/api/v1/events/account_profile_candidates') &&
        options.method == 'GET') {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Unauthorized.'}),
        403,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'data': []}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _NotFoundAdminAccountProfileCandidatesAdapter
    implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);

    if (options.path
            .endsWith('/admin/api/v1/events/account_profile_candidates') &&
        options.method == 'GET') {
      return ResponseBody.fromString(
        jsonEncode({'message': 'Not found.'}),
        404,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }

    return ResponseBody.fromString(
      jsonEncode({'data': []}),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}
