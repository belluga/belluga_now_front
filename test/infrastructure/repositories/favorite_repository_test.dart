import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/event_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_page_dto.dart';
import 'package:belluga_now/infrastructure/repositories/favorite_repository.dart';
import 'package:belluga_now/infrastructure/services/schedule_backend_contract.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppData>(_buildAppData());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test(
    'fetchFavoriteResumes normalizes relative media urls instead of collapsing the favorites row',
    () async {
      GetIt.I.registerSingleton<BackendContract>(
        _StubBackend(
          favoritesBackend: _StubFavoriteBackend(
            favorites: <FavoritePreviewDTO>[
              FavoritePreviewDTO.fromJson({
                'favorite_id': 'fav-1',
                'registry_key': 'account_profile',
                'target_type': 'account_profile',
                'target_id': 'profile-relative',
                'target': {
                  'id': 'profile-relative',
                  'slug': 'profile-relative',
                  'display_name': 'Perfil relativo',
                  'avatar_url':
                      '/api/v1/media/account-profiles/profile-relative/avatar?v=7',
                  'cover_url':
                      'api/v1/media/account-profiles/profile-relative/cover?v=8',
                  'profile_type': 'artist',
                  'can_open_public_detail': true,
                  'public_detail_path': '/parceiro/profile-relative',
                },
                'occurrence_state': const <String, Object?>{},
                'navigation': {
                  'kind': 'account_profile',
                  'target_slug': 'profile-relative',
                  'target_path': '/parceiro/profile-relative',
                  'profile_target_path': '/parceiro/profile-relative',
                  'can_open_public_detail': true,
                },
              }),
            ],
          ),
        ),
      );

      final repository = FavoriteRepository();

      final favorites = await repository.fetchFavoriteResumes();
      final favorite = favorites.single;

      expect(favorites, hasLength(1));
      expect(favorite.accountProfile, isNotNull);
      final accountProfile = favorite.accountProfile!;
      expect(accountProfile.id, 'profile-relative');
      expect(accountProfile.name, 'Perfil relativo');
      expect(accountProfile.slug, 'profile-relative');
      expect(accountProfile.profileType, 'artist');
      expect(
        accountProfile.avatarUrl,
        'https://tenant.test/api/v1/media/account-profiles/profile-relative/avatar?v=7',
      );
      expect(
        accountProfile.coverUrl,
        'https://tenant.test/api/v1/media/account-profiles/profile-relative/cover?v=8',
      );
      expect(accountProfile.canOpenPublicDetail, isTrue);
      expect(accountProfile.publicDetailPath, '/parceiro/profile-relative');
      expect(accountProfile.publicDetailUrl, '/parceiro/profile-relative');
      expect(favorite.title, 'Perfil relativo');
      expect(
        favorite.imageUri?.toString(),
        'https://tenant.test/api/v1/media/account-profiles/profile-relative/avatar?v=7',
      );
      expect(
        favorite.coverImageUrl,
        'https://tenant.test/api/v1/media/account-profiles/profile-relative/cover?v=8',
      );
      expect(favorite.publicDetailUrl, '/parceiro/profile-relative');
    },
  );

  test(
    'paged Favorites preserve backend attribution, order and a separate pin',
    () async {
      FavoritePreviewDTO preview(
        String id, {
        bool live = false,
        bool upcoming = false,
      }) {
        final occurrence = live ? 'live-$id' : (upcoming ? 'next-$id' : null);
        final path = occurrence == null
            ? null
            : '/agenda/evento/show-$id?occurrence=$occurrence';
        return FavoritePreviewDTO.fromJson({
          'registry_key': 'account_profile',
          'target_type': 'account_profile',
          'target_id': id,
          'target': {
            'id': id,
            'slug': id,
            'display_name': id,
            'profile_type': 'artist',
            'can_open_public_detail': true,
            'public_detail_path': '/parceiro/$id',
          },
          'occurrence_state': {
            'live_now_event_occurrence_id': live ? 'live-$id' : null,
            'live_now_event_occurrence_at': live
                ? '2026-03-20T11:00:00Z'
                : null,
            'next_event_occurrence_id': upcoming ? 'next-$id' : null,
            'next_event_occurrence_at': upcoming
                ? '2026-03-21T12:00:00Z'
                : null,
          },
          'navigation': {
            'kind': path == null ? 'account_profile' : 'event',
            'target_path': path ?? '/parceiro/$id',
            'profile_target_path': '/parceiro/$id',
            'event_target_path': path,
            'event_target_slug': occurrence == null ? null : 'show-$id',
            'event_occurrence_id': occurrence,
            'can_open_public_detail': true,
          },
        });
      }

      final live = preview('z-member', live: true, upcoming: true);
      final upcoming = preview('a-member', upcoming: true);
      final fallback = preview('fallback');
      GetIt.I.registerSingleton<BackendContract>(
        _StubBackend(
          favoritesBackend: _StubFavoriteBackend(
            favorites: [live, upcoming, fallback],
            pinned: live,
          ),
        ),
      );
      final repository = FavoriteRepository();
      final first = await repository.fetchFavoriteResumesPage(
        page: 1,
        pageSize: 2,
      );
      expect(first.items.map((item) => item.targetId), [
        'z-member',
        'a-member',
      ]);
      expect(first.items.first.liveNowEventOccurrenceId, 'live-z-member');
      expect(
        first.items.first.nextEventOccurrenceAt,
        DateTime.parse('2026-03-21T12:00:00Z'),
      );
      expect(
        first.items[1].eventTargetPath,
        '/agenda/evento/show-a-member?occurrence=next-a-member',
      );
      expect(first.pinned?.targetId, 'z-member');
      expect(
        first.pinned?.eventTargetPath,
        '/agenda/evento/show-z-member?occurrence=live-z-member',
      );
      expect(first.hasMore, isTrue);
      final second = await repository.fetchFavoriteResumesPage(
        page: 2,
        pageSize: 2,
      );
      expect(second.items.single.targetId, 'fallback');
      expect(second.items.single.eventTargetPath, isNull);
      expect(second.pinned, isNull);
      expect(second.hasMore, isFalse);
    },
  );

  test('account-profile favorite without profile type fails closed', () {
    final favorite = FavoritePreviewDTO.fromJson({
      'favorite_id': 'fav-invalid',
      'registry_key': 'account_profile',
      'target_type': 'account_profile',
      'target_id': 'profile-without-type',
      'target': {
        'id': 'profile-without-type',
        'display_name': 'Perfil sem tipo',
        'can_open_public_detail': true,
        'public_detail_path': '/parceiro/profile-without-type',
      },
      'occurrence_state': const <String, Object?>{},
      'navigation': {
        'kind': 'account_profile',
        'profile_target_path': '/parceiro/profile-without-type',
        'can_open_public_detail': true,
      },
    }).toResume();

    expect(favorite.accountProfile, isNull);
    expect(favorite.publicDetailUrl, isNull);
  });
}

AppData _buildAppData() {
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
          'is_favoritable': {
            'configured': {'value': true, 'parameters': {}},
            'effective': {'value': true, 'parameters': {}},
          },
          'location_policy': {
            'configured': {'value': 'disabled', 'parameters': {}},
            'effective': {'value': 'disabled', 'parameters': {}},
          },
          'is_map_poi_enabled': {
            'configured': {'value': false, 'parameters': {}},
            'effective': {'value': false, 'parameters': {}},
          },
          'is_physical_host_enabled': {
            'configured': {'value': false, 'parameters': {}},
            'effective': {'value': false, 'parameters': {}},
          },
          'is_reference_location_enabled': {
            'configured': {'value': false, 'parameters': {}},
            'effective': {'value': false, 'parameters': {}},
          },
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
  };
  final localInfo = {
    'platformType': PlatformTypeValue()..parse('mobile'),
    'hostname': 'tenant.test',
    'href': 'https://tenant.test',
    'port': null,
    'device': 'test-device',
  };
  return buildAppDataFromInitialization(
    remoteData: remoteData,
    localInfo: localInfo,
  );
}

class _StubBackend extends BackendContract {
  _StubBackend({required this._favoritesBackend});

  final FavoriteBackendContract _favoritesBackend;
  BackendContext? _context;

  @override
  BackendContext? get context => _context;

  @override
  void setContext(BackendContext context) {
    _context = context;
  }

  @override
  AppDataBackendContract get appData => throw UnimplementedError();

  @override
  AuthBackendContract get auth => throw UnimplementedError();

  @override
  TenantBackendContract get tenant => throw UnimplementedError();

  @override
  AccountProfilesBackendContract get accountProfiles =>
      throw UnimplementedError();

  @override
  FavoriteBackendContract get favorites => _favoritesBackend;

  @override
  EventBackendContract get events => throw UnimplementedError();

  @override
  ScheduleBackendContract get schedule => throw UnimplementedError();
}

class _StubFavoriteBackend extends FavoriteBackendContract {
  _StubFavoriteBackend({required this.favorites, this.pinned});

  final List<FavoritePreviewDTO> favorites;
  final FavoritePreviewDTO? pinned;

  @override
  Future<FavoritePreviewPageDTO> fetchFavoritesPage({
    required int page,
    required int pageSize,
  }) async => FavoritePreviewPageDTO(
    items: favorites.skip((page - 1) * pageSize).take(pageSize).toList(),
    pinned: page == 1 ? pinned : null,
    hasMore: page * pageSize < favorites.length,
  );

  @override
  Future<List<FavoritePreviewDTO>> fetchFavorites() async => favorites;

  @override
  Future<void> favoriteAccountProfile(String accountProfileId) async {}

  @override
  Future<void> unfavoriteAccountProfile(String accountProfileId) async {}
}
