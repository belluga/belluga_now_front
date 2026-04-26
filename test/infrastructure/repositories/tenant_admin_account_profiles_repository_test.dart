import 'dart:convert';
import 'dart:typed_data';

import 'package:belluga_form_validation/belluga_form_validation.dart';
import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/landlord_auth_repository_contract.dart';
import 'package:belluga_now/domain/repositories/tenant_admin_account_profiles_repository_contract.dart';
import 'package:belluga_now/domain/services/tenant_admin_tenant_scope_contract.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_media_upload.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_poi_visual.dart';
import 'package:belluga_now/domain/tenant_admin/tenant_admin_profile_type.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_hex_color_value.dart';
import 'package:belluga_now/domain/tenant_admin/value_objects/tenant_admin_required_text_value.dart';
import 'package:belluga_now/infrastructure/repositories/tenant_admin/tenant_admin_account_profiles_repository.dart';
import 'package:belluga_now/infrastructure/services/tenant_admin/tenant_admin_base_url_resolver.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_value/core/stream_value.dart';

import 'support/tenant_admin_paged_stream_contract.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<LandlordAuthRepositoryContract>(_StubAuthRepo());
    GetIt.I.registerSingleton<TenantAdminTenantScopeContract>(
      _StubTenantScope('https://tenant.test'),
    );
    GetIt.I.registerSingleton<AppData>(_buildAppData());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('createAccountProfile uses multipart when upload is provided', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminAccountProfilesRepository(dio: dio);

    await repository.createAccountProfile(
      accountId: tenantAdminAccountProfilesRepoString(
        'account-1',
        defaultValue: '',
        isRequired: true,
      ),
      profileType: tenantAdminAccountProfilesRepoString(
        'personal',
        defaultValue: '',
        isRequired: true,
      ),
      displayName: tenantAdminAccountProfilesRepoString(
        'Profile',
        defaultValue: '',
        isRequired: true,
      ),
      avatarUpload: tenantAdminMediaUploadFromRaw(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'avatar.png',
      ),
    );

    final data = adapter.lastRequest?.data;
    expect(
      adapter.lastRequest?.path,
      contains('https://tenant.test/admin/api/v1/account_profiles'),
    );
    expect(data, isA<FormData>());
    final formData = data as FormData;
    expect(formData.files.any((entry) => entry.key == 'avatar'), isTrue);
    expect(adapter.lastRequest?.contentType, contains('multipart/form-data'));
  });

  test(
    'createAccountProfile sends both avatar and cover files in multipart',
    () async {
      final adapter = _CaptureAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = TenantAdminAccountProfilesRepository(dio: dio);

      await repository.createAccountProfile(
        accountId: tenantAdminAccountProfilesRepoString(
          'account-1',
          defaultValue: '',
          isRequired: true,
        ),
        profileType: tenantAdminAccountProfilesRepoString(
          'personal',
          defaultValue: '',
          isRequired: true,
        ),
        displayName: tenantAdminAccountProfilesRepoString(
          'Profile',
          defaultValue: '',
          isRequired: true,
        ),
        avatarUpload: tenantAdminMediaUploadFromRaw(
          bytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'avatar.png',
        ),
        coverUpload: tenantAdminMediaUploadFromRaw(
          bytes: Uint8List.fromList([4, 5, 6]),
          fileName: 'cover.png',
        ),
      );

      final data = adapter.lastRequest?.data;
      expect(data, isA<FormData>());
      final formData = data as FormData;
      expect(formData.files.any((entry) => entry.key == 'avatar'), isTrue);
      expect(formData.files.any((entry) => entry.key == 'cover'), isTrue);
      expect(adapter.lastRequest?.contentType, contains('multipart/form-data'));
    },
  );

  test('updateAccountProfile sends slug when provided', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminAccountProfilesRepository(dio: dio);

    await repository.updateAccountProfile(
      accountProfileId: tenantAdminAccountProfilesRepoString(
        'profile-1',
        defaultValue: '',
        isRequired: true,
      ),
      slug: tenantAdminAccountProfilesRepoString('profile-slug-custom'),
    );

    expect(adapter.lastRequest?.method, 'PATCH');
    expect(
      adapter.lastRequest?.path,
      contains('https://tenant.test/admin/api/v1/account_profiles/profile-1'),
    );
    final data = adapter.lastRequest?.data;
    expect(data, isA<Map<String, dynamic>>());
    expect((data as Map<String, dynamic>)['slug'], 'profile-slug-custom');
  });

  test('updateAccountProfile keeps empty bio as string payload', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminAccountProfilesRepository(dio: dio);

    await repository.updateAccountProfile(
      accountProfileId: tenantAdminAccountProfilesRepoString(
        'profile-1',
        defaultValue: '',
        isRequired: true,
      ),
      bio: tenantAdminAccountProfilesRepoString(''),
    );

    final data = adapter.lastRequest?.data;
    expect(data, isA<Map<String, dynamic>>());
    expect((data as Map<String, dynamic>)['bio'], '');
  });

  test(
    'updateAccountProfile sends explicit remove avatar/cover flags',
    () async {
      final adapter = _CaptureAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = TenantAdminAccountProfilesRepository(dio: dio);

      await repository.updateAccountProfile(
        accountProfileId: tenantAdminAccountProfilesRepoString(
          'profile-1',
          defaultValue: '',
          isRequired: true,
        ),
        removeAvatar: tenantAdminAccountProfilesRepoBool(
          true,
          defaultValue: true,
        ),
        removeCover: tenantAdminAccountProfilesRepoBool(
          true,
          defaultValue: true,
        ),
      );

      expect(adapter.lastRequest?.method, 'PATCH');
      final data = adapter.lastRequest?.data;
      expect(data, isA<Map<String, dynamic>>());
      final payload = data as Map<String, dynamic>;
      expect(payload['remove_avatar'], isTrue);
      expect(payload['remove_cover'], isTrue);
    },
  );

  test('updateAccountProfile omits bio when null', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminAccountProfilesRepository(dio: dio);

    await repository.updateAccountProfile(
      accountProfileId: tenantAdminAccountProfilesRepoString(
        'profile-1',
        defaultValue: '',
        isRequired: true,
      ),
      bio: null,
      displayName: tenantAdminAccountProfilesRepoString('New Name'),
    );

    final data = adapter.lastRequest?.data;
    expect(data, isA<Map<String, dynamic>>());
    expect((data as Map<String, dynamic>).containsKey('bio'), isFalse);
    expect(data['display_name'], 'New Name');
  });

  test(
    'fetchAccountProfiles maps list media fields without detail fallback',
    () async {
      final adapter = _ProfileListMediaAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = TenantAdminAccountProfilesRepository(dio: dio);

      final profiles = await repository.fetchAccountProfiles(
        accountId: tenantAdminAccountProfilesRepoString(
          'acc-1',
          defaultValue: '',
          isRequired: true,
        ),
      );

      expect(profiles, hasLength(1));
      expect(profiles.first.id, 'profile-1');
      expect(profiles.first.avatarUrl, 'https://cdn.test/profile-1-avatar.png');
      expect(profiles.first.coverUrl, 'https://cdn.test/profile-1-cover.png');
      expect(adapter.requests, hasLength(1));
      expect(
        adapter.requests.first.path,
        contains('/admin/api/v1/account_profiles'),
      );
    },
  );

  test(
    'fetchProfileTypesPage sends pagination params and parses hasMore',
    () async {
      final adapter = _ProfileTypesRoutingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = TenantAdminAccountProfilesRepository(dio: dio);

      final page = await repository.fetchProfileTypesPage(
        page: tenantAdminAccountProfilesRepoInt(1, defaultValue: 1),
        pageSize: tenantAdminAccountProfilesRepoInt(2, defaultValue: 2),
      );

      expect(page.items, hasLength(2));
      expect(page.hasMore, isTrue);
      expect(page.items.first.visual?.mode, TenantAdminPoiVisualMode.icon);
      expect(page.items.first.visual?.icon, 'place');
      expect(page.items.first.visual?.color, '#FF8800');
      expect(page.items.first.visual?.iconColor, '#FFFFFF');
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.queryParameters['page'], 1);
      expect(adapter.requests.single.queryParameters['page_size'], 2);
    },
  );

  test(
    'createProfileTypeWithVisual sends canonical and legacy visual payloads',
    () async {
      final adapter = _CaptureAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = TenantAdminAccountProfilesRepository(dio: dio);

      await repository.createProfileTypeWithVisual(
        type: tenantAdminAccountProfilesRepoString(
          'venue',
          defaultValue: '',
          isRequired: true,
        ),
        label: tenantAdminAccountProfilesRepoString(
          'Venue',
          defaultValue: '',
          isRequired: true,
        ),
        allowedTaxonomies: <TenantAdminAccountProfilesRepoString>[
          tenantAdminAccountProfilesRepoString(
            'genre',
            defaultValue: '',
            isRequired: true,
          ),
        ],
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: TenantAdminFlagValue(true),
          isPoiEnabled: TenantAdminFlagValue(true),
          isReferenceLocationEnabled: TenantAdminFlagValue(true),
          hasBio: TenantAdminFlagValue(true),
          hasContent: TenantAdminFlagValue(true),
          hasTaxonomies: TenantAdminFlagValue(true),
          hasAvatar: TenantAdminFlagValue(true),
          hasCover: TenantAdminFlagValue(true),
          hasEvents: TenantAdminFlagValue(true),
        ),
        visual: TenantAdminPoiVisual.icon(
          iconValue: TenantAdminRequiredTextValue()..parse('place'),
          colorValue: TenantAdminHexColorValue()..parse('#FF8800'),
        ),
      );

      final payload = adapter.lastRequest?.data as Map<String, dynamic>;
      expect(payload['visual'], <String, dynamic>{
        'mode': 'icon',
        'icon': 'place',
        'color': '#FF8800',
        'icon_color': '#FFFFFF',
      });
      expect(payload['poi_visual'], <String, dynamic>{
        'mode': 'icon',
        'icon': 'place',
        'color': '#FF8800',
        'icon_color': '#FFFFFF',
      });
    },
  );

  test('updateProfileTypeWithVisual sends nullable visual payloads', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    final repository = TenantAdminAccountProfilesRepository(dio: dio);

    await repository.updateProfileTypeWithVisual(
      type: tenantAdminAccountProfilesRepoString(
        'venue',
        defaultValue: '',
        isRequired: true,
      ),
      capabilities: TenantAdminProfileTypeCapabilities(
        isFavoritable: TenantAdminFlagValue(true),
        isPoiEnabled: TenantAdminFlagValue(false),
        hasBio: TenantAdminFlagValue(true),
        hasContent: TenantAdminFlagValue(true),
        hasTaxonomies: TenantAdminFlagValue(true),
        hasAvatar: TenantAdminFlagValue(true),
        hasCover: TenantAdminFlagValue(true),
        hasEvents: TenantAdminFlagValue(true),
      ),
      visual: null,
    );

    final payload = adapter.lastRequest?.data as Map<String, dynamic>;
    expect(payload.containsKey('visual'), isTrue);
    expect(payload['visual'], isNull);
    expect(payload.containsKey('poi_visual'), isTrue);
    expect(payload['poi_visual'], isNull);
  });

  test(
    'createProfileTypeWithVisual uses multipart when type_asset upload exists',
    () async {
      final adapter = _CaptureAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = TenantAdminAccountProfilesRepository(dio: dio);

      await repository.createProfileTypeWithVisual(
        type: tenantAdminAccountProfilesRepoString(
          'restaurant',
          defaultValue: '',
          isRequired: true,
        ),
        label: tenantAdminAccountProfilesRepoString(
          'Restaurant',
          defaultValue: '',
          isRequired: true,
        ),
        capabilities: TenantAdminProfileTypeCapabilities(
          isFavoritable: TenantAdminFlagValue(true),
          isPoiEnabled: TenantAdminFlagValue(true),
          isReferenceLocationEnabled: TenantAdminFlagValue(true),
          hasBio: TenantAdminFlagValue(true),
          hasContent: TenantAdminFlagValue(true),
          hasTaxonomies: TenantAdminFlagValue(true),
          hasAvatar: TenantAdminFlagValue(true),
          hasCover: TenantAdminFlagValue(true),
          hasEvents: TenantAdminFlagValue(true),
        ),
        visual: TenantAdminPoiVisual.image(
          imageSource: TenantAdminPoiVisualImageSource.typeAsset,
        ),
        typeAssetUpload: tenantAdminMediaUploadFromRaw(
          bytes: Uint8List.fromList([7, 8, 9]),
          fileName: 'type-asset.png',
        ),
      );

      expect(adapter.lastRequest?.method, 'POST');
      expect(adapter.lastRequest?.contentType, contains('multipart/form-data'));
      final payload = adapter.lastRequest?.data;
      expect(payload, isA<FormData>());
      final formData = payload as FormData;
      expect(formData.files.any((entry) => entry.key == 'type_asset'), isTrue);
      expect(
        formData.fields.any((entry) => entry.key == 'visual[image_source]'),
        isTrue,
      );
      expect(
        formData.fields.any(
          (entry) =>
              entry.key == 'capabilities[is_favoritable]' && entry.value == '1',
        ),
        isTrue,
      );
      expect(
        formData.fields.any(
          (entry) =>
              entry.key == 'capabilities[is_poi_enabled]' && entry.value == '1',
        ),
        isTrue,
      );
      expect(
        formData.fields.any(
          (entry) =>
              entry.key == 'capabilities[is_reference_location_enabled]' &&
              entry.value == '1',
        ),
        isTrue,
      );
    },
  );

  test(
    'updateProfileTypeWithVisual uses multipart patch tunnel for type_asset upload and removal',
    () async {
      final adapter = _CaptureAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = TenantAdminAccountProfilesRepository(dio: dio);

      await repository.updateProfileTypeWithVisual(
        type: tenantAdminAccountProfilesRepoString(
          'restaurant',
          defaultValue: '',
          isRequired: true,
        ),
        visual: TenantAdminPoiVisual.image(
          imageSource: TenantAdminPoiVisualImageSource.typeAsset,
        ),
        typeAssetUpload: tenantAdminMediaUploadFromRaw(
          bytes: Uint8List.fromList([7, 8, 9]),
          fileName: 'type-asset.png',
        ),
        removeTypeAsset: tenantAdminAccountProfilesRepoBool(
          true,
          defaultValue: false,
        ),
      );

      expect(adapter.lastRequest?.method, 'POST');
      expect(adapter.lastRequest?.contentType, contains('multipart/form-data'));
      final payload = adapter.lastRequest?.data;
      expect(payload, isA<FormData>());
      final formData = payload as FormData;
      expect(formData.files.any((entry) => entry.key == 'type_asset'), isTrue);
      expect(formData.fields, contains(const MapEntry('_method', 'PATCH')));
      expect(
        formData.fields.any(
          (entry) => entry.key == 'remove_type_asset' && entry.value == '1',
        ),
        isTrue,
      );
    },
  );

  test(
    'fetchProfileTypeMapPoiProjectionImpact returns projection count',
    () async {
      final adapter = _CaptureAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = TenantAdminAccountProfilesRepository(dio: dio);

      final count = await repository.fetchProfileTypeMapPoiProjectionImpact(
        type: tenantAdminAccountProfilesRepoString(
          'venue',
          defaultValue: '',
          isRequired: true,
        ),
      );

      expect(count.value, 67);
      expect(
        adapter.lastRequest?.path,
        contains(
          '/admin/api/v1/account_profile_types/venue/map_poi_projection_impact',
        ),
      );
    },
  );

  test(
    'load/reset/next follow paged stream contract for profile types',
    () async {
      final adapter = _ProfileTypesRoutingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = TenantAdminAccountProfilesRepository(dio: dio);

      await verifyTenantAdminPagedStreamContract(
        scope: 'account profile types',
        loadFirstPage: () => repository.loadProfileTypes(
          pageSize: tenantAdminAccountProfilesRepoInt(2, defaultValue: 2),
        ),
        loadNextPage: () => repository.loadNextProfileTypesPage(
          pageSize: tenantAdminAccountProfilesRepoInt(2, defaultValue: 2),
        ),
        resetState: repository.resetProfileTypesState,
        readItems: () => repository.profileTypesStreamValue.value,
        readHasMore: () =>
            repository.hasMoreProfileTypesStreamValue.value.value,
        readError: () => repository.profileTypesErrorStreamValue.value?.value,
        expectedCountsPerStep: const [2, 3],
        loadNextCalls: 1,
      );
    },
  );

  test(
    'createAccountProfile preserves structured 422 validation failure',
    () async {
      final adapter = _ProfileCreateValidationAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = TenantAdminAccountProfilesRepository(dio: dio);

      expect(
        repository.createAccountProfile(
          accountId: tenantAdminAccountProfilesRepoString(
            'account-1',
            defaultValue: '',
            isRequired: true,
          ),
          profileType: tenantAdminAccountProfilesRepoString(
            'venue',
            defaultValue: '',
            isRequired: true,
          ),
          displayName: tenantAdminAccountProfilesRepoString(
            'Perfil',
            defaultValue: '',
            isRequired: true,
          ),
        ),
        throwsA(
          isA<FormValidationFailure>()
              .having(
            (error) => error.message,
            'message',
            'The given data was invalid.',
          )
              .having(
            (error) => error.fieldErrors['location.lat'],
            'location.lat error',
            <String>['Latitude obrigatoria.'],
          ),
        ),
      );
    },
  );

  test(
    'createAccountProfile surfaces structured 403 security failure',
    () async {
      final adapter = _ProfileCreateOriginDeniedAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final repository = TenantAdminAccountProfilesRepository(dio: dio);

      expect(
        repository.createAccountProfile(
          accountId: tenantAdminAccountProfilesRepoString(
            'account-1',
            defaultValue: '',
            isRequired: true,
          ),
          profileType: tenantAdminAccountProfilesRepoString(
            'venue',
            defaultValue: '',
            isRequired: true,
          ),
          displayName: tenantAdminAccountProfilesRepoString(
            'Perfil',
            defaultValue: '',
            isRequired: true,
          ),
        ),
        throwsA(
          isA<FormApiFailure>()
              .having((error) => error.statusCode, 'statusCode', 403)
              .having(
                (error) => error.errorCode,
                'errorCode',
                'origin_access_denied',
              ),
        ),
      );
    },
  );
}

class _StubAuthRepo implements LandlordAuthRepositoryContract {
  @override
  bool get hasValidSession => true;

  @override
  String get token => 'test-token';

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

class _StubTenantScope implements TenantAdminTenantScopeContract {
  _StubTenantScope(this._selectedTenantDomain);

  String? _selectedTenantDomain;

  @override
  String? get selectedTenantDomain => _selectedTenantDomain;

  @override
  String get selectedTenantAdminBaseUrl =>
      resolveTenantAdminBaseUrl(_selectedTenantDomain ?? '');

  @override
  StreamValue<String?> get selectedTenantDomainStreamValue =>
      StreamValue<String?>(defaultValue: _selectedTenantDomain);

  @override
  void clearSelectedTenantDomain() {
    _selectedTenantDomain = null;
  }

  @override
  void selectTenantDomain(Object tenantDomain) {
    _selectedTenantDomain = tenantDomain is String
        ? tenantDomain
        : (tenantDomain as dynamic).value as String;
  }
}

class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future? cancelFuture,
  ) async {
    lastRequest = options;
    if (options.path.endsWith('/map_poi_projection_impact')) {
      return ResponseBody.fromString(
        jsonEncode({
          'data': {'profile_type': 'venue', 'projection_count': 67},
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    if (options.path.contains('/v1/account_profile_types')) {
      return ResponseBody.fromString(
        jsonEncode({
          'data': {
            'type': 'venue',
            'label': 'Venue',
            'poi_visual': {
              'mode': 'icon',
              'icon': 'place',
              'color': '#FF8800',
              'icon_color': '#FFFFFF',
            },
            'allowed_taxonomies': <String>[],
            'capabilities': {
              'is_favoritable': true,
              'is_poi_enabled': true,
              'has_bio': true,
              'has_content': true,
              'has_taxonomies': true,
              'has_avatar': true,
              'has_cover': true,
              'has_events': true,
            },
          },
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    final payload = jsonEncode({
      'data': {
        'id': 'profile-1',
        'account_id': 'account-1',
        'profile_type': 'personal',
        'display_name': 'Profile',
      },
    });
    return ResponseBody.fromString(
      payload,
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _ProfileTypesRoutingAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future? cancelFuture,
  ) async {
    requests.add(options);
    final pageRaw = options.queryParameters['page'];
    final page = pageRaw is int ? pageRaw : int.tryParse('$pageRaw') ?? 1;

    if (options.path.endsWith('/v1/account_profile_types') && page == 1) {
      return _jsonResponse({
        'data': [
          _profileType(id: 'pt-1', type: 'artist', label: 'Artist'),
          _profileType(id: 'pt-2', type: 'venue', label: 'Venue'),
        ],
        'current_page': 1,
        'last_page': 2,
      });
    }

    if (options.path.endsWith('/v1/account_profile_types') && page == 2) {
      return _jsonResponse({
        'data': [
          _profileType(id: 'pt-3', type: 'restaurant', label: 'Restaurant'),
        ],
        'current_page': 2,
        'last_page': 2,
      });
    }

    return _jsonResponse({
      'data': const [],
      'current_page': page,
      'last_page': page,
    });
  }

  Map<String, dynamic> _profileType({
    required String id,
    required String type,
    required String label,
  }) {
    return {
      'id': id,
      'type': type,
      'label': label,
      'poi_visual': {
        'mode': 'icon',
        'icon': 'place',
        'color': '#FF8800',
        'icon_color': '#FFFFFF',
      },
      'allowed_taxonomies': const <String>[],
      'capabilities': const {
        'is_favoritable': true,
        'is_poi_enabled': false,
        'has_bio': true,
        'has_content': true,
        'has_taxonomies': true,
        'has_avatar': true,
        'has_cover': true,
        'has_events': false,
      },
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

class _ProfileListMediaAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future? cancelFuture,
  ) async {
    requests.add(options);

    if (options.path.endsWith('/v1/account_profiles')) {
      return _jsonResponse({
        'data': [
          {
            'id': 'profile-1',
            'account_id': 'acc-1',
            'profile_type': 'artist',
            'display_name': 'Profile 1',
            'slug': 'profile-1',
            'avatar_url': 'https://cdn.test/profile-1-avatar.png',
            'cover_url': 'https://cdn.test/profile-1-cover.png',
          },
        ],
      });
    }

    return _jsonResponse({'data': const []});
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

class _ProfileCreateValidationAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'message': 'The given data was invalid.',
        'errors': {
          'location.lat': ['Latitude obrigatoria.'],
        },
      }),
      422,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

class _ProfileCreateOriginDeniedAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'code': 'origin_access_denied',
        'message': 'Direct origin access is not allowed.',
        'correlation_id': 'corr-origin-1',
      }),
      403,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }
}

AppData _buildAppData() {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': [
      {
        'type': 'personal',
        'label': 'Personal',
        'allowed_taxonomies': [],
        'capabilities': {'is_favoritable': false, 'is_poi_enabled': false},
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
