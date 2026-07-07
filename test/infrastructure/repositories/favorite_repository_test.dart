import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/account_profiles_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/app_data_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/auth_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_context.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/favorite_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/static_assets_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/tenant_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/unsupported_static_assets_backend.dart';
import 'package:belluga_now/infrastructure/dal/dao/venue_event_backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dto/favorite/favorite_preview_dto.dart';
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
      expect(favorite.title, 'Perfil relativo');
      expect(
        favorite.imageUri?.toString(),
        'https://tenant.test/api/v1/media/account-profiles/profile-relative/avatar?v=7',
      );
      expect(
        favorite.coverImageUrl,
        'https://tenant.test/api/v1/media/account-profiles/profile-relative/cover?v=8',
      );
      expect(favorite.publicDetailPath, '/parceiro/profile-relative');
    },
  );
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
        'capabilities': {'is_favoritable': true, 'is_poi_enabled': false},
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
  StaticAssetsBackendContract get staticAssets =>
      const UnsupportedStaticAssetsBackend();

  @override
  FavoriteBackendContract get favorites => _favoritesBackend;

  @override
  VenueEventBackendContract get venueEvents => throw UnimplementedError();

  @override
  ScheduleBackendContract get schedule => throw UnimplementedError();
}

class _StubFavoriteBackend extends FavoriteBackendContract {
  _StubFavoriteBackend({required this.favorites});

  final List<FavoritePreviewDTO> favorites;

  @override
  Future<List<FavoritePreviewDTO>> fetchFavorites() async => favorites;

  @override
  Future<void> favoriteAccountProfile(String accountProfileId) async {}

  @override
  Future<void> unfavoriteAccountProfile(String accountProfileId) async {}
}
