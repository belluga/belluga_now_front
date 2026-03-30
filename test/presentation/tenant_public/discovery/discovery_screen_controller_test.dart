import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/partners/account_profile_model.dart';
import 'package:belluga_now/domain/partners/paged_account_profiles_result.dart';
import 'package:belluga_now/domain/repositories/account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/presentation/tenant_public/discovery/controllers/discovery_screen_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:belluga_now/testing/account_profile_model_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AppData>(_buildAppData());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('available discovery types include only favoritable profile types',
      () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(id: _mongoId('a'), type: 'artist', name: 'Artist'),
            _profile(id: _mongoId('b'), type: 'curator', name: 'Curator'),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = DiscoveryScreenController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();

    expect(controller.availableTypesStreamValue.value, ['artist']);
    controller.onDispose();
  });

  test('toggle favorite requires authentication for anonymous users', () async {
    final artist = _profile(id: _mongoId('c'), type: 'artist', name: 'Artist');
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [artist],
          hasMore: false,
        ),
      },
    );
    final controller = DiscoveryScreenController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: false),
    );

    await controller.init();
    final outcome = controller.toggleFavorite(artist.id);

    expect(outcome, FavoriteToggleOutcome.requiresAuthentication);
    expect(repository.toggleCalls, isEmpty);
    controller.onDispose();
  });

  test('discovery loads additional pages with loadNextPage', () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(id: _mongoId('d'), type: 'artist', name: 'First'),
          ],
          hasMore: true,
        ),
        2: pagedAccountProfilesResultFromRaw(
          profiles: [
            _profile(id: _mongoId('e'), type: 'artist', name: 'Second'),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = DiscoveryScreenController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();
    expect(controller.filteredPartnersStreamValue.value, hasLength(1));
    expect(controller.hasMoreStreamValue.value, isTrue);

    await controller.loadNextPage();
    expect(controller.filteredPartnersStreamValue.value, hasLength(2));
    expect(controller.hasMoreStreamValue.value, isFalse);
    controller.onDispose();
  });

  test(
      'discovery search keeps backend matches even when local name/tags do not match',
      () async {
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [
            buildAccountProfileModelFromPrimitives(
              id: _mongoId('f'),
              name: 'Resultado remoto',
              slug: 'slug-exato-remoto',
              type: 'artist',
              tags: const <String>[],
            ),
          ],
          hasMore: false,
        ),
      },
    );
    final controller = DiscoveryScreenController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();
    controller.setSearchQuery('slug-exato-remoto');
    await Future<void>.delayed(const Duration(milliseconds: 450));

    expect(controller.filteredPartnersStreamValue.value, hasLength(1));
    expect(controller.filteredPartnersStreamValue.value.first.slug,
        'slug-exato-remoto');
    expect(repository.pageRequests.last.query, 'slug-exato-remoto');
    controller.onDispose();
  });

  test(
      'discovery stops loading and keeps favoritable chips when first page fails',
      () async {
    final repository = _FailingAccountProfilesRepository();
    final controller = DiscoveryScreenController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();

    expect(controller.isLoadingStreamValue.value, isFalse);
    expect(controller.hasLoadedStreamValue.value, isTrue);
    expect(controller.availableTypesStreamValue.value, ['artist']);
    expect(controller.filteredPartnersStreamValue.value, isEmpty);
    controller.onDispose();
  });

  test('discovery still loads first page when repository init fails', () async {
    final repository = _InitFailingAccountProfilesRepository(
      firstPage: pagedAccountProfilesResultFromRaw(
        profiles: [
          _profile(id: _mongoId('h'), type: 'artist', name: 'Recovered'),
        ],
        hasMore: false,
      ),
    );
    final controller = DiscoveryScreenController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();

    expect(controller.isLoadingStreamValue.value, isFalse);
    expect(controller.hasLoadedStreamValue.value, isTrue);
    expect(controller.availableTypesStreamValue.value, ['artist']);
    expect(controller.filteredPartnersStreamValue.value, hasLength(1));
    expect(
        controller.filteredPartnersStreamValue.value.first.name, 'Recovered');
    expect(repository.fetchPageCalls, 1);
    controller.onDispose();
  });

  test('toggle favorite persists mutation for identified users', () async {
    final artist = _profile(id: _mongoId('g'), type: 'artist', name: 'Artist');
    final repository = _FakeAccountProfilesRepository(
      pages: {
        1: pagedAccountProfilesResultFromRaw(
          profiles: [artist],
          hasMore: false,
        ),
      },
    );
    final controller = DiscoveryScreenController(
      accountProfilesRepository: repository,
      authRepository: _FakeAuthRepository(isAuthorizedValue: true),
    );

    await controller.init();
    final outcome = controller.toggleFavorite(artist.id);

    expect(outcome, FavoriteToggleOutcome.toggled);
    await Future<void>.delayed(Duration.zero);
    expect(repository.toggleCalls, [artist.id]);
    expect(controller.favoriteIdsStreamValue.value.contains(artist.id), isTrue);
    controller.onDispose();
  });
}

class _FakeAccountProfilesRepository extends AccountProfilesRepositoryContract {
  _FakeAccountProfilesRepository({
    required this.pages,
  });

  final Map<int, PagedAccountProfilesResult> pages;
  final List<String> toggleCalls = <String>[];
  final List<_PageRequest> pageRequests = <_PageRequest>[];
  final Map<String, AccountProfileModel> _bySlug =
      <String, AccountProfileModel>{};

  @override
  Future<void> init() async {
    final all =
        pages.values.expand((entry) => entry.profiles).toList(growable: false);
    allAccountProfilesStreamValue.addValue(all);
    favoriteAccountProfileIdsStreamValue
        .addValue(<AccountProfilesRepositoryContractPrimString>{});
    for (final profile in all) {
      _bySlug[profile.slug] = profile;
    }
  }

  @override
  Future<List<AccountProfileModel>> fetchAllAccountProfiles() async {
    return pages.values
        .expand((entry) => entry.profiles)
        .toList(growable: false);
  }

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  }) async {
    final pageValue = page.value;
    final pageSizeValue = pageSize.value;
    final normalizedQueryInput = query?.value;
    final normalizedTypeInput = typeFilter?.value;
    pageRequests.add(
      _PageRequest(
        page: pageValue,
        pageSize: pageSizeValue,
        query: normalizedQueryInput?.trim(),
        typeFilter: normalizedTypeInput?.trim(),
      ),
    );
    var result = pages[pageValue] ??
        pagedAccountProfilesResultFromRaw(
          profiles: <AccountProfileModel>[],
          hasMore: false,
        );

    var profiles = result.profiles;
    final normalizedType = normalizedTypeInput?.trim();
    if (normalizedType != null && normalizedType.isNotEmpty) {
      profiles = profiles
          .where((profile) => profile.type == normalizedType)
          .toList(growable: false);
    }

    final normalizedQuery = normalizedQueryInput?.trim().toLowerCase();
    if (normalizedQuery != null && normalizedQuery.isNotEmpty) {
      profiles = profiles.where((profile) {
        return profile.name.toLowerCase().contains(normalizedQuery) ||
            profile.slug.toLowerCase().contains(normalizedQuery) ||
            profile.tags.any(
              (tag) => tag.value.toLowerCase().contains(normalizedQuery),
            );
      }).toList(growable: false);
    }

    result = pagedAccountProfilesResultFromRaw(
      profiles: profiles,
      hasMore: result.hasMore,
    );

    return result;
  }

  @override
  Future<List<AccountProfileModel>> searchAccountProfiles({
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  }) async {
    final all = await fetchAllAccountProfiles();
    final normalizedType = typeFilter?.value.trim();
    final normalizedQuery = query?.value.trim().toLowerCase();

    return all.where((profile) {
      final typeMatches = normalizedType == null ||
          normalizedType.isEmpty ||
          profile.type == normalizedType;
      if (!typeMatches) return false;
      if (normalizedQuery == null || normalizedQuery.isEmpty) {
        return true;
      }
      return profile.name.toLowerCase().contains(normalizedQuery) ||
          profile.slug.toLowerCase().contains(normalizedQuery) ||
          profile.tags
              .any((tag) => tag.value.toLowerCase().contains(normalizedQuery));
    }).toList(growable: false);
  }

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(
    AccountProfilesRepositoryContractPrimString slug,
  ) async {
    return _bySlug[slug.value];
  }

  @override
  Future<void> toggleFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) async {
    final accountProfileIdValue = accountProfileId.value;
    toggleCalls.add(accountProfileIdValue);
    final current = favoriteAccountProfileIdsStreamValue.value
        .map((entry) => entry.value)
        .toSet();
    if (current.contains(accountProfileIdValue)) {
      current.remove(accountProfileIdValue);
    } else {
      current.add(accountProfileIdValue);
    }
    favoriteAccountProfileIdsStreamValue.addValue(
      current.map(_idValue).toSet(),
    );
  }

  @override
  AccountProfilesRepositoryContractPrimBool isFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) {
    final contains = favoriteAccountProfileIdsStreamValue.value
        .map((entry) => entry.value)
        .contains(accountProfileId.value);
    return AccountProfilesRepositoryContractPrimBool.fromRaw(contains);
  }

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() {
    final ids = favoriteAccountProfileIdsStreamValue.value
        .map((entry) => entry.value)
        .toSet();
    return allAccountProfilesStreamValue.value
        .where((profile) => ids.contains(profile.id))
        .toList(growable: false);
  }

  AccountProfilesRepositoryContractPrimString _idValue(String value) {
    return AccountProfilesRepositoryContractPrimString.fromRaw(value);
  }
}

class _FailingAccountProfilesRepository
    extends AccountProfilesRepositoryContract {
  @override
  Future<void> init() async {
    allAccountProfilesStreamValue.addValue(const <AccountProfileModel>[]);
    favoriteAccountProfileIdsStreamValue
        .addValue(<AccountProfilesRepositoryContractPrimString>{});
  }

  @override
  Future<List<AccountProfileModel>> fetchAllAccountProfiles() async {
    return const <AccountProfileModel>[];
  }

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  }) async {
    throw Exception('forced discovery page failure');
  }

  @override
  Future<List<AccountProfileModel>> searchAccountProfiles({
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  }) async {
    return const <AccountProfileModel>[];
  }

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(
    AccountProfilesRepositoryContractPrimString slug,
  ) async {
    return null;
  }

  @override
  Future<void> toggleFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) async {}

  @override
  AccountProfilesRepositoryContractPrimBool isFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) {
    return AccountProfilesRepositoryContractPrimBool.fromRaw(false);
  }

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() {
    return const <AccountProfileModel>[];
  }
}

class _InitFailingAccountProfilesRepository
    extends AccountProfilesRepositoryContract {
  _InitFailingAccountProfilesRepository({
    required this.firstPage,
  });

  final PagedAccountProfilesResult firstPage;
  int fetchPageCalls = 0;

  @override
  Future<void> init() async {
    throw Exception('forced repository init failure');
  }

  @override
  Future<List<AccountProfileModel>> fetchAllAccountProfiles() async {
    return firstPage.profiles;
  }

  @override
  Future<PagedAccountProfilesResult> fetchAccountProfilesPage({
    required AccountProfilesRepositoryContractPrimInt page,
    required AccountProfilesRepositoryContractPrimInt pageSize,
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  }) async {
    fetchPageCalls += 1;
    if (page.value != 1) {
      return pagedAccountProfilesResultFromRaw(
        profiles: <AccountProfileModel>[],
        hasMore: false,
      );
    }
    return firstPage;
  }

  @override
  Future<List<AccountProfileModel>> searchAccountProfiles({
    AccountProfilesRepositoryContractPrimString? query,
    AccountProfilesRepositoryContractPrimString? typeFilter,
  }) async {
    return firstPage.profiles;
  }

  @override
  Future<AccountProfileModel?> getAccountProfileBySlug(
    AccountProfilesRepositoryContractPrimString slug,
  ) async {
    return null;
  }

  @override
  Future<void> toggleFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) async {}

  @override
  AccountProfilesRepositoryContractPrimBool isFavorite(
    AccountProfilesRepositoryContractPrimString accountProfileId,
  ) {
    return AccountProfilesRepositoryContractPrimBool.fromRaw(false);
  }

  @override
  List<AccountProfileModel> getFavoriteAccountProfiles() {
    return const <AccountProfileModel>[];
  }
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  _FakeAuthRepository({
    required this.isAuthorizedValue,
  });

  final bool isAuthorizedValue;

  @override
  BackendContract get backend => throw UnimplementedError();

  @override
  String get userToken => 'token';

  @override
  void setUserToken(AuthRepositoryContractParamString? token) {}

  @override
  Future<String> getDeviceId() async => 'device-1';

  @override
  Future<String?> getUserId() async => 'user-1';

  @override
  bool get isUserLoggedIn => isAuthorizedValue;

  @override
  bool get isAuthorized => isAuthorizedValue;

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
  Future<void> updateUser(
      UserCustomData data) async {}
}

class _PageRequest {
  const _PageRequest({
    required this.page,
    required this.pageSize,
    required this.query,
    required this.typeFilter,
  });

  final int page;
  final int pageSize;
  final String? query;
  final String? typeFilter;
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
        'allowed_taxonomies': const [],
        'capabilities': {
          'is_favoritable': true,
          'is_poi_enabled': false,
        },
      },
      {
        'type': 'curator',
        'label': 'Curator',
        'allowed_taxonomies': const [],
        'capabilities': {
          'is_favoritable': false,
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

AccountProfileModel _profile({
  required String id,
  required String type,
  required String name,
}) {
  return buildAccountProfileModelFromPrimitives(
    id: id,
    name: name,
    slug: '$name-$type'.toLowerCase().replaceAll(' ', '-'),
    type: type,
  );
}

String _mongoId(String seed) {
  final base =
      seed.codeUnits.fold<int>(0, (acc, item) => acc + item).toRadixString(16);
  final repeated = List<String>.filled(24, base).join().substring(0, 24);
  return repeated;
}
