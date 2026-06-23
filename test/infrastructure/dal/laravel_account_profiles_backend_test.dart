import 'dart:convert';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/map/geo_distance.dart';
import 'package:belluga_now/domain/map/value_objects/city_coordinate.dart';
import 'package:belluga_now/domain/map/value_objects/distance_in_meters_value.dart';
import 'package:belluga_now/domain/map/value_objects/latitude_value.dart';
import 'package:belluga_now/domain/map/value_objects/longitude_value.dart';
import 'package:belluga_now/domain/repositories/app_data_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/user_location_repository_contract.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_bool_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/account_profiles_repository_taxonomy_filter.dart';
import 'package:belluga_now/domain/repositories/value_objects/auth_repository_contract_values.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_duration_value.dart';
import 'package:belluga_now/domain/repositories/value_objects/user_location_repository_contract_text_value.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/partners_backend/laravel_account_profiles_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/services/location_origin_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      _FakeAuthRepository(),
    );
    _registerAppData();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('fetchAccountProfiles hits account_profiles and parses profiles',
      () async {
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': [
          {
            'id': validId,
            'display_name': 'Artist One',
            'slug': 'artist-one',
            'profile_type': 'artist',
            'can_open_public_detail': true,
            'public_detail_path': '/parceiro/artist-one',
            'taxonomy_terms': [
              {'type': 'genre', 'value': 'indie'},
            ],
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final page = await backend.fetchAccountProfilesPage(
      page: 1,
      pageSize: 30,
    );
    final profiles = page.profiles;

    expect(adapter.lastRequest?.uri.path, '/api/v1/account_profiles');
    expect(adapter.lastRequest?.queryParameters['page'], 1);
    expect(adapter.lastRequest?.queryParameters['per_page'], 30);
    expect(adapter.lastRequest?.headers['Authorization'], 'Bearer test-token');
    expect(profiles, hasLength(1));
    expect(profiles.first.name, 'Artist One');
    expect(profiles.first.slug, 'artist-one');
    expect(profiles.first.canOpenPublicDetail, isTrue);
    expect(profiles.first.publicDetailPath, '/parceiro/artist-one');
  });

  test(
      'fetchAccountProfiles accepts backend-valid three-character display_name',
      () async {
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': [
          {
            'id': validId,
            'display_name': 'Ane',
            'slug': 'ane',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final page = await backend.fetchAccountProfilesPage(
      page: 1,
      pageSize: 30,
    );

    expect(page.profiles, hasLength(1));
    expect(page.profiles.first.name, 'Ane');
    expect(page.profiles.first.slug, 'ane');
  });

  test(
      'fetchAccountProfiles falls back to humanized slug when persisted display_name is too short',
      () async {
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': [
          {
            'id': validId,
            'display_name': 'An',
            'slug': 'casa-marracini',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final page = await backend.fetchAccountProfilesPage(
      page: 1,
      pageSize: 30,
    );

    expect(page.profiles, hasLength(1));
    expect(page.profiles.first.name, 'Casa Marracini');
  });

  test(
      'fetchAccountProfiles isolates malformed rows and preserves valid profiles in mixed batches',
      () async {
    final invalidId = _generateMongoId();
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': [
          {
            'id': invalidId,
            'display_name': 'An',
            'slug': '___',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
          },
          {
            'id': validId,
            'display_name': 'Valid Artist',
            'slug': 'valid-artist',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final page = await backend.fetchAccountProfilesPage(
      page: 1,
      pageSize: 30,
    );

    expect(page.profiles, hasLength(1));
    expect(page.profiles.single.name, 'Valid Artist');
    expect(page.profiles.single.slug, 'valid-artist');
  });

  test(
      'fetchAccountProfiles prefers taxonomy term name or label over slug-like value',
      () async {
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': [
          {
            'id': validId,
            'display_name': 'Artist One',
            'slug': 'artist-one',
            'profile_type': 'artist',
            'taxonomy_terms': [
              {
                'type': 'genre',
                'value': 'brasilidades',
                'name': 'Brasilidades',
              },
              {
                'type': 'vibe',
                'value': 'beira-mar',
                'label': 'Beira Mar',
              },
              {
                'type': 'fallback',
                'value': 'capixaba',
              },
            ],
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final page = await backend.fetchAccountProfilesPage(
      page: 1,
      pageSize: 30,
    );

    expect(page.profiles, hasLength(1));
    expect(
      page.profiles.first.tags.map((entry) => entry.value).toList(),
      <String>['Brasilidades', 'Beira Mar', 'capixaba'],
    );
  });

  test('fetchAccountProfiles bootstraps auth token when empty', () async {
    final authRepository = GetIt.I.get<AuthRepositoryContract<UserContract>>()
        as _FakeAuthRepository;
    authRepository.setUserToken(authRepoString(''));

    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': [
          {
            'id': validId,
            'display_name': 'Artist One',
            'slug': 'artist-one',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    await backend.fetchAccountProfilesPage(
      page: 1,
      pageSize: 30,
    );

    expect(authRepository.initCallCount, 1);
    expect(
      adapter.lastRequest?.headers['Authorization'],
      'Bearer refreshed-token',
    );
  });

  test('fetchAccountProfiles parses direct distance meters field', () async {
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': [
          {
            'id': validId,
            'display_name': 'Nearby Venue',
            'slug': 'nearby-venue',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
            'distance_meters': 1425.75,
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final page = await backend.fetchAccountProfilesPage(
      page: 1,
      pageSize: 30,
    );
    final profiles = page.profiles;

    expect(profiles, hasLength(1));
    expect(profiles.first.distanceMeters, closeTo(1425.75, 0.001));
  });

  test('fetchAccountProfiles parses runtime discovery facets', () async {
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': [
          {
            'id': validId,
            'display_name': 'Artist One',
            'slug': 'artist-one',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
          },
        ],
        'has_more': true,
        'discovery_filter_facets': {
          'surface': 'discovery.account_profiles',
          'filter_keys': ['venue', 'artist_public'],
          'taxonomy_options': {
            'cuisine': {
              'key': 'cuisine',
              'label': 'Cozinha',
              'terms': [
                {'value': 'italian', 'label': 'Italian'},
                {'value': 'japanese', 'label': 'Japanese'},
              ],
            },
          },
        },
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final page = await backend.fetchAccountProfilesPage(
      page: 1,
      pageSize: 30,
    );

    expect(page.discoveryFilterFacets, isNotNull);
    expect(
      page.discoveryFilterFacets?.surface,
      'discovery.account_profiles',
    );
    expect(
      page.discoveryFilterFacets?.filterKeys,
      <String>{'venue', 'artist_public'},
    );
    expect(
      page.discoveryFilterFacets?.taxonomyOptionsByKey['cuisine']?.terms
          .map((term) => term.value)
          .toList(),
      <String>['italian', 'japanese'],
    );
  });

  test('fetchAccountProfiles parses canonical runtime discovery catalog',
      () async {
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': [
          {
            'id': validId,
            'display_name': 'Artist One',
            'slug': 'artist-one',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
          },
        ],
        'has_more': true,
        'discovery_filter_catalog': {
          'surface': 'discovery.account_profiles',
          'filters': [
            {
              'key': 'venue',
              'label': 'Venue',
              'target': 'account_profile',
              'query': {
                'entities': ['account_profile'],
                'types_by_entity': {
                  'account_profile': ['venue'],
                },
              },
            },
          ],
          'type_options': {
            'account_profile': [
              {
                'value': 'venue',
                'label': 'Venue',
                'allowed_taxonomies': ['cuisine'],
              },
            ],
          },
          'taxonomy_options': {
            'cuisine': {
              'key': 'cuisine',
              'label': 'Cozinha',
              'terms': [
                {'value': 'italian', 'label': 'Italian'},
              ],
            },
          },
        },
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final page = await backend.fetchAccountProfilesPage(
      page: 1,
      pageSize: 30,
    );

    expect(page.discoveryFilterCatalog, isNotNull);
    expect(
      page.discoveryFilterCatalog?.filters.map((item) => item.key).toList(),
      <String>['venue'],
    );
    expect(
      page.discoveryFilterCatalog?.taxonomyOptionsByKey['cuisine']?.terms
          .map((term) => term.value)
          .toList(),
      <String>['italian'],
    );
  });

  test('fetchAccountProfileBySlug hits direct slug endpoint and parses profile',
      () async {
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': {
          'id': validId,
          'display_name': 'Slug Detail Artist',
          'slug': 'slug-detail-artist',
          'profile_type': 'artist',
          'can_open_public_detail': true,
          'public_detail_path': '/parceiro/slug-detail-artist',
          'taxonomy_terms': const [],
        },
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final profile = await backend.fetchAccountProfileBySlug(
      'slug-detail-artist',
    );

    expect(adapter.lastRequest?.uri.path,
        '/api/v1/account_profiles/slug-detail-artist');
    expect(adapter.lastRequest?.queryParameters, isEmpty);
    expect(profile, isNotNull);
    expect(profile?.name, 'Slug Detail Artist');
    expect(profile?.slug, 'slug-detail-artist');
    expect(profile?.canOpenPublicDetail, isTrue);
    expect(
      profile?.publicDetailPath,
      '/parceiro/slug-detail-artist',
    );
  });

  test(
      'fetchAccountProfileBySlug falls back to humanized slug when persisted display_name is invalid',
      () async {
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': {
          'id': validId,
          'display_name': 'An',
          'slug': 'slug-detail-artist',
          'profile_type': 'artist',
          'taxonomy_terms': const [],
        },
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final profile = await backend.fetchAccountProfileBySlug(
      'slug-detail-artist',
    );

    expect(profile, isNotNull);
    expect(profile?.name, 'Slug Detail Artist');
    expect(profile?.slug, 'slug-detail-artist');
  });

  test(
      'fetchAccountProfileBySlug requires public detail path before enabling navigation',
      () async {
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': {
          'id': validId,
          'display_name': 'Slug Detail Artist',
          'slug': 'slug-detail-artist',
          'profile_type': 'artist',
          'can_open_public_detail': true,
          'taxonomy_terms': const [],
        },
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final profile = await backend.fetchAccountProfileBySlug(
      'slug-detail-artist',
    );

    expect(profile, isNotNull);
    expect(profile?.slug, 'slug-detail-artist');
    expect(profile?.canOpenPublicDetail, isFalse);
    expect(profile?.publicDetailPath, isNull);
  });

  test('fetchAccountProfileBySlug parses nested account profile groups',
      () async {
    final parentId = _generateMongoId();
    final partnerAId = _generateMongoId();
    final partnerBId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': {
          'id': parentId,
          'display_name': 'Parent Profile',
          'slug': 'parent-profile',
          'profile_type': 'venue',
          'taxonomy_terms': const [],
          'nested_profile_groups': [
            {
              'id': 'parceiros',
              'label': 'Parceiros',
              'order': 1,
              'profiles': [
                {
                  'id': partnerBId,
                  'display_name': 'Parceiro B',
                  'slug': 'parceiro-b',
                  'profile_type': 'artist',
                  'can_open_public_detail': true,
                  'public_detail_path': '/parceiro/parceiro-b',
                  'avatar_url': 'https://tenant.test/b.png',
                  'taxonomy_terms': [
                    {'name': 'Música', 'value': 'musica'},
                  ],
                },
                {
                  'id': partnerAId,
                  'display_name': 'Parceiro A',
                  'slug': 'parceiro-a',
                  'profile_type': 'artist',
                  'can_open_public_detail': false,
                },
              ],
            },
          ],
        },
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final profile = await backend.fetchAccountProfileBySlug('parent-profile');

    expect(profile, isNotNull);
    expect(profile!.nestedProfileGroups, hasLength(1));
    final group = profile.nestedProfileGroups.single;
    expect(group.id, 'parceiros');
    expect(group.label, 'Parceiros');
    expect(group.profiles.map((entry) => entry.slug).toList(), [
      'parceiro-b',
      'parceiro-a',
    ]);
    expect(group.profiles.first.canOpenPublicDetail, isTrue);
    expect(group.profiles.first.publicDetailPath, '/parceiro/parceiro-b');
    expect(group.profiles.last.canOpenPublicDetail, isFalse);
    expect(group.profiles.first.avatarUrl, 'https://tenant.test/b.png');
    expect(group.profiles.first.tags.single.value, 'Música');
  });

  test(
      'fetchAccountProfileBySlug keeps nested members without slug when not navigable',
      () async {
    final parentId = _generateMongoId();
    final partnerId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': {
          'id': parentId,
          'display_name': 'Parent Profile',
          'slug': 'parent-profile',
          'profile_type': 'venue',
          'taxonomy_terms': const [],
          'nested_profile_groups': [
            {
              'id': 'parceiros',
              'label': 'Parceiros',
              'order': 1,
              'profiles': [
                {
                  'id': partnerId,
                  'display_name': 'Parceiro Sem Link',
                  'profile_type': 'guest_public',
                  'can_open_public_detail': false,
                  'public_detail_path': null,
                },
              ],
            },
          ],
        },
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final profile = await backend.fetchAccountProfileBySlug('parent-profile');

    expect(profile, isNotNull);
    final member = profile!.nestedProfileGroups.single.profiles.single;
    expect(member.slug, isEmpty);
    expect(member.canOpenPublicDetail, isFalse);
    expect(member.publicDetailPath, isNull);
  });

  test(
      'fetchAccountProfileBySlug applies short-name and fallback rules to nested members',
      () async {
    final parentId = _generateMongoId();
    final shortNameId = _generateMongoId();
    final fallbackId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': {
          'id': parentId,
          'display_name': 'Parent Profile',
          'slug': 'parent-profile',
          'profile_type': 'venue',
          'taxonomy_terms': const [],
          'nested_profile_groups': [
            {
              'id': 'parceiros',
              'label': 'Parceiros',
              'order': 1,
              'profiles': [
                {
                  'id': shortNameId,
                  'display_name': 'Ane',
                  'slug': 'ane',
                  'profile_type': 'artist',
                  'can_open_public_detail': true,
                  'public_detail_path': '/parceiro/ane',
                },
                {
                  'id': fallbackId,
                  'display_name': 'An',
                  'slug': 'casa-marracini',
                  'profile_type': 'artist',
                  'can_open_public_detail': false,
                },
              ],
            },
          ],
        },
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final profile = await backend.fetchAccountProfileBySlug('parent-profile');

    expect(profile, isNotNull);
    final members = profile!.nestedProfileGroups.single.profiles;
    expect(members, hasLength(2));
    expect(members.map((entry) => entry.name).toList(), [
      'Ane',
      'Casa Marracini',
    ]);
  });

  test('fetchAccountProfileBySlug returns null on not found', () async {
    final adapter = _RecordingAdapter(
      response: {
        'message': 'Not Found',
      },
      statusCode: 404,
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final profile = await backend.fetchAccountProfileBySlug('missing-slug');

    expect(
        adapter.lastRequest?.uri.path, '/api/v1/account_profiles/missing-slug');
    expect(profile, isNull);
  });

  test(
      'fetchAccountProfileBySlug parses agenda_occurrences into occurrence-first account profile agenda',
      () async {
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': {
          'id': validId,
          'display_name': 'Casa Marracini',
          'slug': 'casa-marracini',
          'profile_type': 'restaurant',
          'taxonomy_terms': const [],
          'agenda_occurrences': const [
            {
              'event_id': '507f1f77bcf86cd799439021',
              'occurrence_id': '507f1f77bcf86cd799439121',
              'slug': 'jazz-na-orla',
              'title': 'Jazz na Orla',
              'type': {
                'name': 'Show',
              },
              'date_time_start': '2026-04-04T21:00:00Z',
              'date_time_end': '2026-04-04T23:00:00Z',
              'location': {'label': 'Deck Principal'},
              'venue': {
                'id': '507f1f77bcf86cd799439011',
                'display_name': 'Casa Marracini',
                'hero_image_url': 'https://example.com/casa.jpg',
              },
              'linked_account_profiles': [
                {
                  'id': '507f1f77bcf86cd799439099',
                  'display_name': 'Marco Aurélio',
                  'avatar_url': 'https://example.com/marco.jpg',
                }
              ],
            },
            {
              'event_id': '507f1f77bcf86cd799439021',
              'occurrence_id': '507f1f77bcf86cd799439122',
              'slug': 'jazz-na-orla',
              'title': 'Jazz na Orla',
              'type': {
                'name': 'Show',
              },
              'date_time_start': '2026-04-05T21:00:00Z',
              'location': {'label': 'Deck Principal'},
              'venue': {
                'id': '507f1f77bcf86cd799439011',
                'display_name': 'Casa Marracini',
              },
              'linked_account_profiles': [
                {
                  'id': '507f1f77bcf86cd799439099',
                  'display_name': 'Marco Aurélio',
                }
              ],
            },
          ],
        },
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final profile = await backend.fetchAccountProfileBySlug('casa-marracini');

    expect(profile, isNotNull);
    expect(profile?.agendaEvents, hasLength(2));
    expect(profile?.agendaEvents.first.eventId, '507f1f77bcf86cd799439021');
    expect(
        profile?.agendaEvents.first.occurrenceId, '507f1f77bcf86cd799439121');
    expect(profile?.agendaEvents.last.occurrenceId, '507f1f77bcf86cd799439122');
    expect(
      profile?.agendaEvents.first.primaryCounterpart?.id,
      '507f1f77bcf86cd799439099',
    );
    expect(
      profile?.agendaEvents.first.primaryCounterpart?.title,
      'Marco Aurélio',
    );
    expect(profile?.agendaEvents.first.venueId, '507f1f77bcf86cd799439011');
    expect(profile?.agendaEvents.first.venueTitle, 'Casa Marracini');
    expect(profile?.agendaEvents.first.eventTypeLabel, 'Show');
    expect(profile?.agendaEvents.first.location, 'Deck Principal');
  });

  test(
      'fetchAccountProfilesPage keeps profile_type unset when no explicit type filter',
      () async {
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': [
          {
            'id': validId,
            'display_name': 'Artist One',
            'slug': 'artist-one',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
          },
        ],
        'current_page': 1,
        'last_page': 1,
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    await backend.fetchAccountProfilesPage(
      page: 1,
      pageSize: 30,
      allowedTypes: const ['artist', 'venue'],
    );

    expect(adapter.lastRequest?.uri.path, '/api/v1/account_profiles');
    expect(adapter.lastRequest?.queryParameters.containsKey('profile_type'),
        isFalse);
    expect(adapter.lastRequest?.queryParameters.containsKey('filter'), isFalse);
  });

  test('fetchAccountProfilesPage sends canonical type and taxonomy filters',
      () async {
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': [
          {
            'id': validId,
            'display_name': 'Filtered Artist',
            'slug': 'filtered-artist',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
          },
        ],
        'current_page': 1,
        'last_page': 1,
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    await backend.fetchAccountProfilesPage(
      page: 1,
      pageSize: 30,
      typeFilters: const ['artist', 'venue'],
      taxonomyFilters: [
        AccountProfilesRepositoryTaxonomyFilter.fromRaw(
          type: 'genre',
          value: 'rock',
        ),
      ],
    );

    final queryParameters = adapter.lastRequest?.queryParameters;
    expect(queryParameters?['profile_type'], const ['artist', 'venue']);
    expect(queryParameters?['filter'], {
      'profile_type': const ['artist', 'venue'],
    });
    expect(queryParameters?['taxonomy[0][type]'], 'genre');
    expect(queryParameters?['taxonomy[0][value]'], 'rock');
  });

  test('fetchAccountProfiles computes distance using tenant default origin',
      () async {
    _registerAppData(
        defaultOriginLat: -20.670000, defaultOriginLng: -40.500000);
    final validId = _generateMongoId();
    final targetLat = -20.664500;
    final targetLng = -40.494200;
    final adapter = _RecordingAdapter(
      response: {
        'data': [
          {
            'id': validId,
            'display_name': 'Computed Distance',
            'slug': 'computed-distance',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
            'location': {
              'lat': targetLat,
              'lng': targetLng,
            },
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final page = await backend.fetchAccountProfilesPage(
      page: 1,
      pageSize: 30,
    );
    final profiles = page.profiles;

    expect(profiles, hasLength(1));
    final expected = haversineDistanceMeters(
      coordinateA: _coordinate(lat: -20.670000, lng: -40.500000),
      coordinateB: _coordinate(lat: targetLat, lng: targetLng),
    );
    expect(profiles.first.distanceMeters, closeTo(expected.value, 0.001));
  });

  test('fetchAccountProfiles preserves location coordinates for detail UI',
      () async {
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'data': [
          {
            'id': validId,
            'display_name': 'Casa Marracini',
            'slug': 'casa-marracini',
            'profile_type': 'restaurant',
            'taxonomy_terms': const [],
            'location': {
              'lat': -20.7389,
              'lng': -40.8212,
            },
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final page = await backend.fetchAccountProfilesPage(
      page: 1,
      pageSize: 30,
    );
    final profiles = page.profiles;

    expect(profiles, hasLength(1));
    expect(profiles.first.locationLat, closeTo(-20.7389, 0.0001));
    expect(profiles.first.locationLng, closeTo(-40.8212, 0.0001));
  });

  test('fetchNearbyAccountProfiles calls near endpoint with origin', () async {
    _registerAppData(
      defaultOriginLat: -20.670000,
      defaultOriginLng: -40.500000,
    );
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'page': 1,
        'page_size': 5,
        'has_more': false,
        'data': [
          {
            'id': validId,
            'display_name': 'Nearby Venue',
            'slug': 'nearby-venue',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
            'distance_meters': 240.0,
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final profiles = await backend.fetchNearbyAccountProfiles(pageSize: 5);

    expect(adapter.lastRequest?.uri.path, '/api/v1/account_profiles/near');
    expect(adapter.lastRequest?.queryParameters['origin_lat'], -20.67);
    expect(adapter.lastRequest?.queryParameters['origin_lng'], -40.5);
    expect(adapter.lastRequest?.queryParameters['page'], 1);
    expect(adapter.lastRequest?.queryParameters['page_size'], 5);
    expect(profiles, hasLength(1));
    expect(profiles.first.name, 'Nearby Venue');
    expect(profiles.first.distanceMeters, closeTo(240.0, 0.001));
  });

  test('fetchNearbyAccountProfiles accepts four-character display_name',
      () async {
    _registerAppData(
      defaultOriginLat: -20.670000,
      defaultOriginLng: -40.500000,
    );
    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'page': 1,
        'page_size': 5,
        'has_more': false,
        'data': [
          {
            'id': validId,
            'display_name': 'Bela',
            'slug': 'bela',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
            'distance_meters': 240.0,
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    final profiles = await backend.fetchNearbyAccountProfiles(pageSize: 5);

    expect(profiles, hasLength(1));
    expect(profiles.first.name, 'Bela');
  });

  test('fetchNearbyAccountProfiles sends canonical type and taxonomy filters',
      () async {
    _registerAppData(
      defaultOriginLat: -20.670000,
      defaultOriginLng: -40.500000,
    );
    final adapter = _RecordingAdapter(
      response: {
        'page': 1,
        'page_size': 5,
        'has_more': false,
        'data': const [],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
      ),
    );

    await backend.fetchNearbyAccountProfiles(
      pageSize: 5,
      typeFilters: const ['venue'],
      taxonomyFilters: [
        AccountProfilesRepositoryTaxonomyFilter.fromRaw(
          type: 'cuisine',
          value: 'italian',
        ),
      ],
    );

    final queryParameters = adapter.lastRequest?.queryParameters;
    expect(queryParameters?['profile_type'], 'venue');
    expect(queryParameters?['taxonomy[0][type]'], 'cuisine');
    expect(queryParameters?['taxonomy[0][value]'], 'italian');
  });

  test(
      'fetchNearbyAccountProfiles ensures user location snapshot before resolving origin',
      () async {
    _registerAppData(
      defaultOriginLat: null,
      defaultOriginLng: null,
    );
    final userLocationRepository = _FakeUserLocationRepository(
      loadedCoordinate: _coordinate(lat: -20.661, lng: -40.492),
    );
    GetIt.I.registerSingleton<UserLocationRepositoryContract>(
      userLocationRepository,
    );

    final validId = _generateMongoId();
    final adapter = _RecordingAdapter(
      response: {
        'page': 1,
        'page_size': 5,
        'has_more': false,
        'data': [
          {
            'id': validId,
            'display_name': 'Nearby Artist',
            'slug': 'nearby-artist',
            'profile_type': 'artist',
            'taxonomy_terms': const [],
            'distance_meters': 120.0,
          },
        ],
      },
    );
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelAccountProfilesBackend(
      dio: dio,
      locationOriginService: LocationOriginService(
        appDataRepository: _FakeAppDataRepository(GetIt.I.get<AppData>()),
        userLocationRepository: userLocationRepository,
      ),
    );

    final profiles = await backend.fetchNearbyAccountProfiles(pageSize: 5);

    expect(adapter.lastRequest?.uri.path, '/api/v1/account_profiles/near');
    expect(adapter.lastRequest?.queryParameters['origin_lat'], -20.661);
    expect(adapter.lastRequest?.queryParameters['origin_lng'], -40.492);
    expect(profiles, hasLength(1));
    expect(profiles.first.distanceMeters, closeTo(120.0, 0.001));
  });
}

class _FakeAppDataRepository extends AppDataRepositoryContract {
  _FakeAppDataRepository(AppData appData)
      : _appData = appData,
        maxRadiusMetersStreamValue = StreamValue<DistanceInMetersValue>(
          defaultValue: DistanceInMetersValue.fromRaw(
            appData.mapRadiusMaxMeters,
            defaultValue: appData.mapRadiusMaxMeters,
          ),
        );

  final AppData _appData;

  @override
  AppData get appData => _appData;

  @override
  Future<void> init() async {}

  @override
  final StreamValue<ThemeMode?> themeModeStreamValue =
      StreamValue<ThemeMode?>(defaultValue: ThemeMode.light);

  @override
  ThemeMode get themeMode => themeModeStreamValue.value ?? ThemeMode.light;

  @override
  Future<void> setThemeMode(AppThemeModeValue mode) async {
    themeModeStreamValue.addValue(mode.value);
  }

  @override
  final StreamValue<DistanceInMetersValue> maxRadiusMetersStreamValue;

  @override
  DistanceInMetersValue get maxRadiusMeters => maxRadiusMetersStreamValue.value;

  @override
  Future<void> setMaxRadiusMeters(DistanceInMetersValue meters) async {
    maxRadiusMetersStreamValue.addValue(meters);
  }
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  String _token = 'test-token';
  int initCallCount = 0;

  @override
  BackendContract get backend => throw UnimplementedError();

  @override
  String get userToken => _token;

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {
    _token = token?.value ?? '';
  }

  @override
  Future<String> getDeviceId() async => 'device-1';

  @override
  Future<String?> getUserId() async => 'user-1';

  @override
  bool get isUserLoggedIn => true;

  @override
  bool get isAuthorized => true;

  @override
  Future<void> init() async {
    initCallCount += 1;
    if (_token.trim().isEmpty) {
      _token = 'refreshed-token';
    }
  }

  @override
  Future<void> ensureTenantPublicIdentityReady() async {
    await init();
  }

  @override
  Future<void> autoLogin() async {}

  @override
  Future<void> loginWithEmailPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> signUpWithEmailPassword(
    AuthRepositoryContractParamString name,
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString password,
  ) async {}

  @override
  Future<void> sendTokenRecoveryPassword(
    AuthRepositoryContractParamString email,
    AuthRepositoryContractParamString codigoEnviado,
  ) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<void> createNewPassword(
    AuthRepositoryContractParamString newPassword,
    AuthRepositoryContractParamString confirmPassword,
  ) async {}

  @override
  Future<void> sendPasswordResetEmail(
    AuthRepositoryContractParamString email,
  ) async {}

  @override
  Future<void> updateUser(UserCustomData data) async {}
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({
    required Map<String, dynamic> response,
    this.statusCode = 200,
  }) : _response = response;

  final Map<String, dynamic> _response;
  final int statusCode;
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      jsonEncode(_response),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _FakeUserLocationRepository extends UserLocationRepositoryContract {
  _FakeUserLocationRepository({
    required this.loadedCoordinate,
  });

  final CityCoordinate loadedCoordinate;
  int ensureLoadedCalls = 0;

  @override
  final userLocationStreamValue = StreamValue<CityCoordinate?>();

  @override
  final lastKnownLocationStreamValue = StreamValue<CityCoordinate?>();

  @override
  final lastKnownCapturedAtStreamValue = StreamValue<DateTime?>();

  @override
  final lastKnownAccuracyStreamValue = StreamValue<double?>();

  @override
  final lastKnownAddressStreamValue = StreamValue<String?>();

  @override
  final locationResolutionPhaseStreamValue =
      StreamValue<LocationResolutionPhase>(
    defaultValue: LocationResolutionPhase.unknown,
  );

  @override
  Future<void> ensureLoaded() async {
    ensureLoadedCalls += 1;
    lastKnownLocationStreamValue.addValue(loadedCoordinate);
  }

  @override
  Future<void> setLastKnownAddress(
    UserLocationRepositoryContractTextValue? address,
  ) async {}

  @override
  Future<bool> warmUpIfPermitted() async {
    lastKnownLocationStreamValue.addValue(loadedCoordinate);
    return true;
  }

  @override
  Future<bool> refreshIfPermitted({
    UserLocationRepositoryContractDurationValue? minInterval,
  }) async =>
      true;

  @override
  Future<String?> resolveUserLocation({
    Object? timeout,
    UserLocationRepositoryContractBoolValue? requestPermissionIfNeededValue,
  }) async =>
      null;

  @override
  Future<bool> startTracking({
    LocationTrackingMode mode = LocationTrackingMode.mapForeground,
  }) async =>
      true;

  @override
  Future<void> stopTracking() async {}
}

CityCoordinate _coordinate({
  required double lat,
  required double lng,
}) {
  return CityCoordinate(
    latitudeValue: LatitudeValue()..parse(lat.toString()),
    longitudeValue: LongitudeValue()..parse(lng.toString()),
  );
}

AppData _buildAppDataWithSettings({
  double? defaultOriginLat,
  double? defaultOriginLng,
}) {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': [
      {
        'type': 'artist',
        'label': 'Artist',
        'allowed_taxonomies': [],
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': false,
        },
      },
    ],
    'domains': ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': {
      'brightness_default': 'light',
      'primary_seed_color': '#FFFFFF',
      'secondary_seed_color': '#000000',
    },
    'main_color': '#FFFFFF',
    'tenant_id': 'tenant-1',
    'telemetry': const {'trackers': []},
    'telemetry_context': const {'location_freshness_minutes': 5},
    'firebase': null,
    'push': null,
    'settings': {
      'map_ui': {
        if (defaultOriginLat != null && defaultOriginLng != null)
          'default_origin': {
            'lat': defaultOriginLat,
            'lng': defaultOriginLng,
          },
      },
    },
  };
  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };
  return buildAppDataFromInitialization(
      remoteData: remoteData, localInfo: localInfo);
}

void _registerAppData({
  double? defaultOriginLat,
  double? defaultOriginLng,
}) {
  if (GetIt.I.isRegistered<AppData>()) {
    GetIt.I.unregister<AppData>();
  }
  GetIt.I.registerSingleton<AppData>(
    _buildAppDataWithSettings(
      defaultOriginLat: defaultOriginLat,
      defaultOriginLng: defaultOriginLng,
    ),
  );
}

String _generateMongoId() {
  // 24-char hex string to satisfy MongoIDValue validation in AccountProfileModel.
  return DateTime.now()
      .microsecondsSinceEpoch
      .toRadixString(16)
      .padLeft(24, '0')
      .substring(0, 24);
}
