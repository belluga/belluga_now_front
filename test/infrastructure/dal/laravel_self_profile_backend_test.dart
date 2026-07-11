import 'dart:convert';
import 'dart:typed_data';

import 'package:belluga_now/domain/app_data/app_data.dart';
import 'package:belluga_now/domain/app_data/value_object/platform_type_value.dart';
import 'package:belluga_now/domain/repositories/auth_repository_contract.dart';
import 'package:belluga_now/domain/user/user_contract.dart';
import 'package:belluga_now/domain/user/user_profile_media_upload.dart';
import 'package:belluga_now/domain/user/value_objects/user_display_name_value.dart';
import 'package:belluga_now/domain/user/value_objects/user_profile_media_bytes_value.dart';
import 'package:belluga_now/domain/value_objects/description_value.dart';
import 'package:belluga_now/domain/value_objects/domain_boolean_value.dart';
import 'package:belluga_now/infrastructure/dal/dao/backend_contract.dart';
import 'package:belluga_now/infrastructure/dal/dao/laravel_backend/self_profile_backend/laravel_self_profile_backend.dart';
import 'package:belluga_now/testing/app_data_test_factory.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:value_object_pattern/domain/value_objects/generic_string_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await GetIt.I.reset();
    GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
      _FakeAuthRepository(),
    );
    GetIt.I.registerSingleton<AppData>(_buildAppData());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  test('text-only profile updates use JSON PATCH', () async {
    final adapter = _RecordingAdapter(response: const {'ok': true});
    final dio = Dio()..httpClientAdapter = adapter;
    final backend = LaravelSelfProfileBackend(dio: dio);

    final displayNameValue = UserDisplayNameValue(
      isRequired: false,
      minLenght: null,
    )..parse('Nome Persistido');
    final bioValue = DescriptionValue(defaultValue: '', minLenght: null)
      ..parse('Bio persistida');

    await backend.updateCurrentProfile(
      displayNameValue: displayNameValue,
      bioValue: bioValue,
    );

    final request = adapter.lastRequest;
    expect(request, isNotNull);
    expect(request?.method, 'PATCH');
    expect(request?.uri.path, '/api/v1/profile');
    expect(request?.contentType, contains('application/json'));
    expect(request?.data, isA<Map<String, dynamic>>());
    final jsonBody = request!.data as Map<String, dynamic>;
    expect(jsonBody['_method'], isNull);
    expect(jsonBody['name'], 'Nome Persistido');
    expect(jsonBody['bio'], 'Bio persistida');
    expect(request.headers['Authorization'], 'Bearer test-token');
  });

  test(
    'avatar profile updates use multipart POST with method override',
    () async {
      final adapter = _RecordingAdapter(response: const {'ok': true});
      final dio = Dio()..httpClientAdapter = adapter;
      final backend = LaravelSelfProfileBackend(dio: dio);

      final upload = UserProfileMediaUpload(
        bytesValue: UserProfileMediaBytesValue()
          ..set(Uint8List.fromList([1, 2, 3])),
        fileNameValue: GenericStringValue(isRequired: true, minLenght: null)
          ..parse('avatar.png'),
        mimeTypeValue: GenericStringValue(isRequired: false, minLenght: null)
          ..parse('image/png'),
      );

      await backend.updateCurrentProfile(avatarUpload: upload);

      final request = adapter.lastRequest;
      expect(request, isNotNull);
      expect(request?.method, 'POST');
      expect(request?.uri.path, '/api/v1/profile');
      expect(request?.contentType, contains('multipart/form-data'));
      expect(request?.data, isA<FormData>());
      final formData = request!.data as FormData;
      expect(
        formData.fields.any(
          (entry) => entry.key == '_method' && entry.value == 'PATCH',
        ),
        isTrue,
      );
      expect(formData.files.any((entry) => entry.key == 'avatar'), isTrue);
      expect(request.headers['Authorization'], 'Bearer test-token');
    },
  );

  test(
    'remove-avatar updates use multipart POST with method override',
    () async {
      final adapter = _RecordingAdapter(response: const {'ok': true});
      final dio = Dio()..httpClientAdapter = adapter;
      final backend = LaravelSelfProfileBackend(dio: dio);
      final removeAvatarValue = DomainBooleanValue(defaultValue: false)
        ..parse('true');

      await backend.updateCurrentProfile(removeAvatarValue: removeAvatarValue);

      final request = adapter.lastRequest;
      expect(request, isNotNull);
      expect(request?.method, 'POST');
      expect(request?.uri.path, '/api/v1/profile');
      expect(request?.contentType, contains('multipart/form-data'));
      expect(request?.data, isA<FormData>());
      final formData = request!.data as FormData;
      expect(
        formData.fields.any(
          (entry) => entry.key == '_method' && entry.value == 'PATCH',
        ),
        isTrue,
      );
      expect(
        formData.fields.any(
          (entry) => entry.key == 'remove_avatar' && entry.value == 'true',
        ),
        isTrue,
      );
    },
  );

  test(
    'avatar multipart updates rebuild the request body after unauthorized retry',
    () async {
      final authRepository = _FakeAuthRepository();
      await GetIt.I.reset();
      GetIt.I.registerSingleton<AuthRepositoryContract<UserContract>>(
        authRepository,
      );
      GetIt.I.registerSingleton<AppData>(_buildAppData());

      final adapter = _UnauthorizedThenSuccessAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final backend = LaravelSelfProfileBackend(dio: dio);

      final upload = UserProfileMediaUpload(
        bytesValue: UserProfileMediaBytesValue()
          ..set(Uint8List.fromList([1, 2, 3])),
        fileNameValue: GenericStringValue(isRequired: true, minLenght: null)
          ..parse('avatar.png'),
        mimeTypeValue: GenericStringValue(isRequired: false, minLenght: null)
          ..parse('image/png'),
      );

      await backend.updateCurrentProfile(avatarUpload: upload);

      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.first.method, 'POST');
      expect(adapter.requests.last.method, 'POST');
      expect(adapter.requests.first.headers['Authorization'], 'Bearer test-token');
      expect(
        adapter.requests.last.headers['Authorization'],
        'Bearer refreshed-token',
      );
      expect(authRepository.recoverCalls, 1);
      expect(adapter.requests.first.data, isA<FormData>());
      expect(adapter.requests.last.data, isA<FormData>());
      expect(identical(adapter.requests.first.data, adapter.requests.last.data), isFalse);

      final retriedBody = adapter.requests.last.data as FormData;
      expect(
        retriedBody.fields.any(
          (entry) => entry.key == '_method' && entry.value == 'PATCH',
        ),
        isTrue,
      );
      expect(
        retriedBody.files.any((entry) => entry.key == 'avatar'),
        isTrue,
      );
    },
  );
}

class _FakeAuthRepository extends AuthRepositoryContract<UserContract> {
  String _token = 'test-token';
  int recoverCalls = 0;

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
  Future<void> init() async {}

  @override
  Future<void> ensureTenantPublicIdentityReady() async {
    await init();
  }

  @override
  Future<void> recoverTenantPublicIdentityAfterUnauthorizedPublicRequest() async {
    recoverCalls += 1;
    _token = 'refreshed-token';
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
  _RecordingAdapter({required this.response});

  final Map<String, dynamic> response;
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
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _UnauthorizedThenSuccessAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requests.length == 1) {
      throw DioException.badResponse(
        statusCode: 401,
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: 401,
          data: const {'message': 'Unauthorized'},
        ),
      );
    }

    return ResponseBody.fromString(
      jsonEncode(const {'ok': true}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

AppData _buildAppData() {
  final remoteData = {
    'name': 'Tenant Test',
    'type': 'tenant',
    'main_domain': 'https://tenant.test',
    'profile_types': const [
      {
        'type': 'artist',
        'label': 'Artist',
        'allowed_taxonomies': [],
        'capabilities': {'is_favoritable': true, 'is_poi_enabled': false},
      },
    ],
    'domains': const ['https://tenant.test'],
    'app_domains': const [],
    'theme_data_settings': const {
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
